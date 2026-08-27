import 'package:fcm_app/domains/push/push_tap.dart';

/// The seam that keeps `firebase_messaging` out of the widget tree and out of
/// the tests.
abstract interface class PushSource {
  /// Raw FCM `data` maps, in arrival order.
  Stream<Map<String, Object?>> get payloads;

  /// Notification taps, fed by FCM's own tray entries. A banner the app posted itself
  /// is reported by `NotificationPresenter.taps` instead.
  Stream<PushTap> get taps;

  Future<String?> token();

  /// Asks the user for notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  Future<void> dispose();
}
