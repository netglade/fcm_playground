import 'package:core/core.dart';

/// Shows a received push as an operating-system notification — the same shape of
/// seam as `PushSource`, so the widget tests never construct
/// `flutter_local_notifications`.
///
/// Only foreground arrivals reach [show]. While the app is backgrounded, FCM's own
/// SDK draws the tray entry, so anything restored from storage has already been
/// notified once and must not be notified again.
abstract interface class NotificationPresenter {
  /// Creates the notification channel and starts listening for taps.
  Future<void> initialize();

  Future<void> show(PushMessage message);

  /// Ids of messages whose banner the user tapped.
  Stream<String> get taps;

  Future<void> dispose();
}
