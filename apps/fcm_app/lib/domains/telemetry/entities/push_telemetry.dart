import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// What the push pipeline reports the life of a message to.
///
/// An interface rather than the concrete `TelemetryReporter` so a hook can default
/// to silence — otherwise every `PushRepository` test would build a Drift database
/// and an HTTP client.
///
/// [record] stores; [flush] talks to the network. Which of the two a hook may call
/// is call-site policy — see `report_push_event.dart` — because the reporter
/// cannot see whether it runs in an isolate that is about to be killed.
abstract interface class PushTelemetry {
  /// Buffers one event of [type] against [traceId].
  Future<void> record(
    TelemetryEventType type, {
    required String traceId,
    String? scenarioId,
    String? detail,
  });

  /// Sends what is buffered.
  Future<void> flush();
}
