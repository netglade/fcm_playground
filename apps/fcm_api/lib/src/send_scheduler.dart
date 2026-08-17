import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_sender.dart';
import 'run_store.dart';
import 'send_message.dart';
import 'send_outcome.dart';
import 'telemetry_store.dart';

/// Decides when a scheduled send happens, and records what became of it.
///
/// It owns no timer. [tick] is driven from outside — `bin/server.dart` calls it once
/// a second — so the tests drive it with a fake clock and the suite creates no real
/// timer at all. That is the same seam [sendMessage] already has through its
/// injected `now` and `newTraceId`.
///
/// It is a delayed trigger rather than a second route to FCM: every dispatch goes
/// through [sendMessage], so a scheduled send writes the same telemetry an immediate
/// one does.
class SendScheduler {
  SendScheduler({
    required this._runs,
    required this._telemetry,
    required this._sender,
    required this._newId,
    required this._now,
  });

  /// How late a due item may be, when the server comes back up, and still be sent.
  ///
  /// Both halves matter. A server restarted two seconds before a batch was due
  /// should still run it. A push delivered three hours after somebody asked for it
  /// arrives in a state nobody was observing and pollutes the latency figures it
  /// lands in — [RunItemState.missed] is the honest answer there.
  static const graceOnRestart = Duration(seconds: 120);

  final RunStore _runs;
  final TelemetryStore _telemetry;
  final FcmSender _sender;

  /// Mints run ids and trace ids alike — both are ids unique across every server,
  /// which is exactly what `newTraceId` produces.
  final String Function() _newId;

  /// Read once per item actually dispatched, never once per [tick]. A batch
  /// claimed together is still sent one item after another, and a single reading
  /// shared across all of them would stamp every one with the instant the *tick*
  /// happened rather than the instant each individual send did — turning the
  /// server's own serialisation delay into what `GET /latency` reports as
  /// delivery latency. [tick]'s own `now` parameter stays the due-time argument;
  /// this is a separate reading for a separate question.
  final DateTime Function() _now;

  /// Guards against a tick starting while the previous one is still awaiting FCM.
  /// A slow send must not have the next second's tick claim the same batch again.
  bool _ticking = false;

  /// Turns a request into a stored run, due from [now].
  Future<ScheduledRun> schedule(
    ScheduleRunRequest request,
    DateTime now,
  ) async {
    final run = ScheduledRun(
      id: _newId(),
      createdAt: now,
      items: [
        for (final (index, item) in request.items.indexed)
          ScheduledRunItem(
            index: index,
            request: item,
            dueAt: now.add(
              Duration(
                seconds: request.delaySeconds + index * request.spacingSeconds,
              ),
            ),
          ),
      ],
    );
    await _runs.save(run);

    return run;
  }

  /// Dispatches everything due at or before [now].
  Future<void> tick(DateTime now) async {
    if (_ticking) {
      return;
    }
    _ticking = true;
    try {
      for (final (runId, item) in await _runs.claimDue(now)) {
        await _dispatch(runId, item);
      }
    } finally {
      _ticking = false;
    }
  }

  Future<ScheduledRun?> find(String runId) => _runs.find(runId);

  Future<List<RunSummary>> recent() async => [
    for (final run in await _runs.recent()) RunSummary.of(run),
  ];

  /// Cancels every still-pending item of [runId], or null when there is no such run.
  ///
  /// A claimed item is deliberately out of reach: at that moment it is already on
  /// its way to FCM, and reporting it cancelled would be a lie the timeline then
  /// contradicts.
  Future<int?> cancel(String runId) => _runs.cancelPending(runId);

  /// Settles every outstanding item after a restart.
  ///
  /// Runs once, before the server starts serving, so nothing else is touching the
  /// store while it works.
  Future<void> recover(DateTime now) async {
    for (final run in await _runs.unfinished()) {
      for (final item in run.items) {
        if (item.state == RunItemState.dispatching) {
          await _resolveInterrupted(run.id, item);
        } else if (item.state == RunItemState.pending &&
            !item.dueAt.isAfter(now)) {
          await _settleOverdue(run.id, item, now);
        }
      }
    }
  }

  /// Sends a lately-due item, or gives up on one nobody can still be waiting for.
  Future<void> _settleOverdue(
    String runId,
    ScheduledRunItem item,
    DateTime now,
  ) async {
    if (now.difference(item.dueAt) > graceOnRestart) {
      await _runs.updateItem(
        runId,
        item.copyWith(
          state: RunItemState.missed,
          error:
              'The server was not running when this was due, and it was too '
              'late to send by the time it came back.',
        ),
      );

      return;
    }

    await _dispatch(runId, item.copyWith(state: RunItemState.dispatching));
  }

  /// Reads the outcome of an item the process died in the middle of.
  ///
  /// Nothing is assumed: `sendMessage` writes `queued` before asking FCM and `sent`
  /// or `send_failed` after, so the telemetry already holds the answer. A trace with
  /// only `queued` means FCM never answered, which is a failure — claiming it sent
  /// would put a phantom into the latency figures.
  Future<void> _resolveInterrupted(String runId, ScheduledRunItem item) async {
    final traceId = item.traceId;
    if (traceId == null) {
      await _runs.updateItem(
        runId,
        item.copyWith(
          state: RunItemState.failed,
          error: 'The server stopped before the send was recorded.',
        ),
      );

      return;
    }

    final events = await _telemetry.eventsForTraces([traceId]);
    final sent = _firstOfType(events, TelemetryEventType.sent);
    if (sent != null) {
      await _runs.updateItem(
        runId,
        item.copyWith(
          state: RunItemState.sent,
          messageId: sent.detail,
          dispatchedAt: sent.at,
        ),
      );

      return;
    }

    final failed = _firstOfType(events, TelemetryEventType.sendFailed);
    await _runs.updateItem(
      runId,
      item.copyWith(
        state: RunItemState.failed,
        error: failed == null
            ? 'The server stopped while sending, and FCM never answered.'
            : 'FCM refused it (${failed.detail}).',
        dispatchedAt: failed?.at,
      ),
    );
  }

  /// Sends one claimed item and writes its outcome back.
  ///
  /// The trace id is minted and **persisted before the send**, which is what makes an
  /// interrupted dispatch recoverable: without it, an item found in `dispatching`
  /// after a crash would name no trace to look up.
  ///
  /// Everything from that persist onward sits inside one `try`. `sendMessage`
  /// only ever throws when the transport itself failed — a socket fault, a
  /// `HandshakeException`, the production client's own token refresh — because it
  /// already catches `FcmSendException` and reports that as a normal
  /// [SendRejected]; and `_runs.updateItem` can throw too, on a store that is
  /// briefly unavailable. Either kind must still leave this item `failed` and let
  /// the rest of the batch go out, exactly as a `SendRejected` already does — the
  /// spec's "one item's failure does not stop a batch" draws no line between a
  /// bad token and a dropped connection.
  ///
  /// The `try` starts at the trace-id persist itself, not at `sendMessage`,
  /// deliberately: that first `updateItem` can throw too, and if it did and this
  /// only wrapped the send, the item would stay `dispatching` in the store —
  /// correct until the next restart's [recover] notices it, but silent for
  /// however long that takes, and this method would have returned having
  /// written nothing despite the batch supposedly continuing. Catching it here
  /// means the *same* unexpected-failure handling covers both: the item is
  /// written `failed` immediately, using [pending] so a trace id minted before
  /// the failure is not thrown away.
  Future<void> _dispatch(String runId, ScheduledRunItem claimed) async {
    final traceId = claimed.traceId ?? _newId();
    final pending = claimed.copyWith(traceId: traceId);
    try {
      await _runs.updateItem(runId, pending);

      final now = _now();
      final outcome = await sendMessage(
        pending.request,
        sender: _sender,
        now: () => now,
        newTraceId: () => traceId,
        telemetry: _telemetry,
      );

      await _runs.updateItem(runId, switch (outcome) {
        SendSucceeded(:final response) => pending.copyWith(
          state: RunItemState.sent,
          messageId: response.messageId,
          dispatchedAt: now,
        ),
        SendRejected(:final error) => pending.copyWith(
          state: RunItemState.failed,
          error: error.message,
          dispatchedAt: now,
        ),
      });
    } on Object catch (error) {
      await _runs.updateItem(
        runId,
        pending.copyWith(
          state: RunItemState.failed,
          error: 'The scheduler could not complete this send: $error',
          dispatchedAt: _now(),
        ),
      );
    }
  }
}

TelemetryEvent? _firstOfType(
  List<TelemetryEvent> events,
  TelemetryEventType type,
) {
  for (final event in events) {
    if (event.type == type) {
      return event;
    }
  }

  return null;
}
