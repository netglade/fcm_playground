import 'package:core/core.dart';

import '../../push/entities/push_tap.dart';

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

  /// Taps on banners this presenter drew, which are always foreground ones.
  Stream<PushTap> get taps;

  /// Ids of messages whose banner the user swiped away.
  ///
  /// A tap never appears here: the plugin documents that dismissing via a tap or
  /// `cancel` is not reported as a dismissal, so one press cannot produce both an
  /// `opened` and a `dismissed`.
  ///
  /// Only banners *this presenter drew* can be reported, which means foreground ones.
  /// A tray entry FCM drew itself was never posted through the plugin.
  Stream<String> get dismissals;

  Future<void> dispose();
}
