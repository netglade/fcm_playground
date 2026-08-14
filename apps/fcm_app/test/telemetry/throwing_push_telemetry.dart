import 'package:fcm_app/telemetry/push_telemetry.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [PushTelemetry] that fails, as a corrupt database or an absent plugin does.
///
/// It keeps what it was [attempted] with before throwing, so a test can tell "the
/// hook swallowed a real failure" apart from "the hook never tried" — the two
/// ways a `completes` expectation can pass.
class ThrowingPushTelemetry implements PushTelemetry {
  /// Fails at the first step, before anything is stored.
  ThrowingPushTelemetry() : _recordThrows = true;

  /// Stores, then fails at the send — the other half of the same promise, and
  /// the one a hook reaches only because recording worked.
  ThrowingPushTelemetry.onFlush() : _recordThrows = false;

  final bool _recordThrows;

  /// Every event type [record] was called with, failure included.
  final attempted = <TelemetryEventType>[];

  /// How many times [flush] was called, failure included.
  int flushes = 0;

  @override
  Future<void> record(
    TelemetryEventType type, {
    required String traceId,
    String? scenarioId,
    String? detail,
  }) async {
    attempted.add(type);
    if (_recordThrows) {
      throw StateError('the telemetry database is unavailable');
    }
  }

  @override
  Future<void> flush() async {
    flushes++;

    throw StateError('the telemetry database is unavailable');
  }
}
