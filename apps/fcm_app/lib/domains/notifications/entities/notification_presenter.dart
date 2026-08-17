import 'package:core/core.dart';

/// Shows a received push as an operating-system notification.
///
/// The same shape of seam as `PushSource`: an interface, one implementation over
/// a plugin, and a do-nothing stand-in — so the widget tests never construct
/// `flutter_local_notifications`.
///
/// Only foreground arrivals reach [show]. While the app is backgrounded, FCM's
/// own SDK draws the tray entry, so anything restored from storage has already
/// been notified once and must not be notified again.
abstract interface class NotificationPresenter {
  /// Creates the notification channel and starts listening for taps.
  Future<void> initialize();

  /// Posts a banner for a message that has just arrived in the foreground.
  Future<void> show(PushMessage message);

  /// Ids of messages whose banner the user tapped.
  Stream<String> get taps;

  /// Releases the tap stream.
  Future<void> dispose();
}
