/// The seam that keeps `firebase_messaging` out of the widget tree and out of
/// the tests.
abstract interface class PushSource {
  /// Raw FCM `data` maps, in arrival order.
  Stream<Map<String, Object?>> get payloads;

  /// Ids of messages whose notification the user tapped, fed by FCM's own tray
  /// notifications. A banner the app posted itself is reported by
  /// `NotificationPresenter.taps` instead.
  Stream<String> get taps;

  Future<String?> token();

  /// Asks the user for notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  Future<void> dispose();
}
