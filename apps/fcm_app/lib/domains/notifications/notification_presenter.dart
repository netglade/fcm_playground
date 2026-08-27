import 'package:fcm_app/domains/push/push.dart';

/// Shows a received push as an OS notification.
///
/// A seam like `PushSource`, so widget tests never build
/// `flutter_local_notifications`.
///
/// [show] draws foreground arrivals only. The background isolate draws
/// data-only payloads by calling the plugin directly — it has no `getIt` and
/// cannot reach this interface — but [taps] and [dismissals] still report
/// those, because every action opens the app and every dismissal is routed
/// with `dismissIsolate: main`.
abstract interface class NotificationPresenter {
  /// Creates the notification channel and starts listening for taps.
  Future<void> initialize();

  Future<void> show(PushMessage message);

  /// Taps on a banner this app drew: `foreground`, `background`, or `killed`
  /// for a press that started the process.
  ///
  /// A killed-state press is emitted once, from [initialize] — it happened
  /// before anything could subscribe.
  ///
  /// Single-subscription, not broadcast: a broadcast controller would silently
  /// drop that launching press. A second subscription throws.
  Stream<PushTap> get taps;

  /// Ids of messages whose banner the user swiped away.
  ///
  /// Android only, and never fires for a tap — so one press cannot produce
  /// both `opened` and `dismissed`. Silent for FCM-drawn tray entries and for
  /// swipes after the process dies.
  ///
  /// Single-subscription, like [taps].
  Stream<String> get dismissals;

  /// Removes every notification this app drew, and forgets their group
  /// membership.
  ///
  /// The tray only — the inbox keeps its messages. This is the only way out of
  /// an ongoing notification, which cannot be swiped away.
  Future<void> clearAll();

  Future<void> dispose();
}
