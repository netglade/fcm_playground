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
        await _dispatch(runId, item, now);
      }
    } finally {
      _ticking = false;
    }
  }

  Future<ScheduledRun?> find(String runId) => _runs.find(runId);

  Future<List<RunSummary>> recent() async => [
    for (final run in await _runs.recent()) RunSummary.of(run),
  ];

  /// Sends one claimed item and writes its outcome back.
  ///
  /// The trace id is minted and **persisted before the send**, which is what makes an
  /// interrupted dispatch recoverable: without it, an item found in `dispatching`
  /// after a crash would name no trace to look up.
  Future<void> _dispatch(
    String runId,
    ScheduledRunItem claimed,
    DateTime now,
  ) async {
    final traceId = claimed.traceId ?? _newId();
    final pending = claimed.copyWith(traceId: traceId);
    await _runs.updateItem(runId, pending);

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
  }
}
