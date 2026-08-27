import 'package:fcm_app/domains/push/pressed_action.dart';
import 'package:fcm_app/domains/push/pressed_action_store.dart';

/// A [PressedActionStore] that keeps nothing, for the tests and for the app
/// running without storage — the same seam `SilentNotificationPresenter` and
/// `SilentPushTelemetry` provide for their domains.
class SilentPressedActionStore implements PressedActionStore {
  const SilentPressedActionStore();

  @override
  Future<Map<String, PressedAction>> load() async => const {};

  @override
  Future<void> save(Map<String, PressedAction> actions) => Future<void>.value();
}
