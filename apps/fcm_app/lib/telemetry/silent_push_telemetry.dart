import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'push_telemetry.dart';

/// A [PushTelemetry] that observes nothing, for a pipeline wired without one.
///
/// The default every hook falls back to, the same way
/// `SilentNotificationPresenter` is the default banner: an app whose telemetry
/// database could not be opened must still receive pushes, and a test that is
/// about the inbox must not have to supply a reporter to get one.
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
