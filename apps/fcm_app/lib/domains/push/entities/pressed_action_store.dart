import 'pressed_action.dart';

/// Where pressed actions are kept so the detail page can still report one after
/// a restart.
///
/// One collection, replaced whole, unlike `PushPayloadStore`'s two: only the UI
/// isolate ever writes here. Every observation route for a press lands in the
/// main isolate, because every action opens the app.
abstract interface class PressedActionStore {
  Future<Map<String, PressedAction>> load();

  /// Replaces the kept presses. The caller has already pruned.
  Future<void> save(Map<String, PressedAction> actions);
}
