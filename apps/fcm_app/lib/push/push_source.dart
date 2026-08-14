/// A source of incoming push payloads.
///
/// This interface is the seam that keeps `firebase_messaging` out of the widget
/// tree and out of the tests. Production code uses `FirebasePushSource`; tests
/// use a fake that emits payloads on demand.
abstract interface class PushSource {
  /// Raw FCM `data` maps, in arrival order.
  Stream<Map<String, Object?>> get payloads;

  /// Ids of messages whose notification the user tapped.
  ///
  /// Fed by FCM's own tray notifications — `onMessageOpenedApp` while the app was
  /// backgrounded, and the launch message when it was terminated. A banner the
  /// app posted itself is reported by `NotificationPresenter.taps` instead.
  Stream<String> get taps;

  /// The device's registration token, or `null` when unavailable.
  Future<String?> token();

  /// Asks the user for notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Releases the underlying subscription and stream.
  Future<void> dispose();
}
