import 'package:fcm_app/domains/telemetry/push_telemetry.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [PushTelemetry] that observes nothing — the default every hook falls back to,
/// so an app whose telemetry database could not be opened still receives pushes.
class SilentPushTelemetry implements PushTelemetry {
  const SilentPushTelemetry();

  @override
  Future<void> record(
    TelemetryEventType type, {
    required String traceId,
    String? scenarioId,
    String? detail,
  }) => Future<void>.value();

  @override
  Future<void> flush() => Future<void>.value();
}
