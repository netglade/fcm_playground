import 'package:fcm_api/src/fcm_sender.dart';
import 'package:fcm_api/src/run_store.dart';
import 'package:fcm_api/src/send_message.dart';
import 'package:fcm_api/src/send_outcome.dart';
import 'package:fcm_api/src/telemetry_store.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Decides when a scheduled send happens, and records what became of it.
///
/// Owns no timer: [tick] is driven from outside — `bin/server.dart` once a
/// second — so tests use a fake clock and the suite creates no real timer.
///
/// A delayed trigger, not a second route to FCM. Every dispatch goes through
/// [sendMessage], so a scheduled send writes the same telemetry as an immediate
/// one.
class SendScheduler {
  SendScheduler({
    required this._runs,
    required this._telemetry,
    required this._sender,
    required this._newId,
    required this._now,
  });

  /// How late a due item may be after a restart and still be sent.
  ///
  /// A server back up two seconds late should still run the batch. One three
  /// hours late arrives in a state nobody was watching and pollutes the latency
  /// figures — [RunItemState.missed] is the honest answer there.
  static const graceOnRestart = Duration(seconds: 120);

  final RunStore _runs;
  final TelemetryStore _telemetry;
  final FcmSender _sender;

  /// Mints run ids and trace ids alike — both want global uniqueness.
  final String Function() _newId;

  /// Read once per dispatched item, never once per [tick]: a claimed batch is
  /// still sent one item at a time, and one shared reading would charge the
  /// server's own serialisation delay to `GET /latency`. [tick]'s `now` stays the
  /// due-time argument — a separate question.
  final DateTime Function() _now;

  /// Stops the next second's tick claiming a batch the current one is still
  /// awaiting FCM for.
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

  /// Cancels every still-pending item of [runId], or null when no such run
  /// exists.
  ///
  /// A claimed item is out of reach on purpose — it is already on its way to FCM,
  /// so "cancelled" would be a lie the timeline contradicts.
  Future<int?> cancel(String runId) => _runs.cancelPending(runId);

  /// Settles every outstanding item after a restart.
  ///
  /// Runs once before the server starts serving, so nothing else touches the
  /// store meanwhile.
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
  /// Nothing is assumed: `sendMessage` writes `queued` before asking FCM and the
  /// result after, so telemetry holds the answer. Only `queued` means FCM never
  /// replied — a failure, and calling it sent would put a phantom in the latency
  /// figures.
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
  /// The trace id is minted and **persisted before the send**, which is what
  /// makes an interrupted dispatch recoverable: otherwise an item found
  /// `dispatching` after a crash names no trace to look up.
  ///
  /// The `try` starts at that persist, not at `sendMessage`, so both failures it
  /// can raise land in the same handler: a transport fault from the send, and an
  /// unavailable store from the write. Either must leave the item `failed` and
  /// let the batch continue. Wrapping only the send would leave a failed write
  /// stuck in `dispatching` until the next [recover] — silent for however long
  /// that takes.
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
