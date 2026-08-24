import 'package:core/core.dart';

import '../../push/entities/push_tap.dart';

/// Shows a received push as an operating-system notification — the same shape of
/// seam as `PushSource`, so the widget tests never construct
/// `flutter_local_notifications`.
///
/// [show] is for foreground arrivals only — the app is on screen, so the app has to
/// draw the banner itself. That is not the whole of what this presenter's plugin
/// draws, though: a data-only payload (the shape the action scenarios use, since
/// Android cannot put buttons on a notification FCM drew) is never drawn by FCM in
/// *any* state, so the background isolate draws those itself, calling the plugin
/// directly through the same notification-details builder [show] uses — that
/// isolate has no `getIt` and cannot reach an instance of this interface. [taps] and
/// [dismissals] still see those presses and swipes: every action button shows UI
/// (opens the app) and every dismissal is routed with `dismissIsolate: main`, so
/// both land on the callbacks [initialize] registered on the main isolate, whichever
/// isolate drew the notification the user acted on.
abstract interface class NotificationPresenter {
  /// Creates the notification channel and starts listening for taps.
  Future<void> initialize();

  Future<void> show(PushMessage message);

  /// Taps on a banner this app drew, in any of the three states: `foreground` for
  /// one pressed while on screen, `background` for one pressed while backgrounded,
  /// and `killed` for one whose press started the process — the last of these is
  /// reported once, from [initialize], since it happened before anything could
  /// have subscribed yet.
  ///
  /// This is a single-subscription stream, not a broadcast one: [initialize] can emit
  /// the launching press before a caller has had the chance to subscribe, and a
  /// broadcast controller silently discards an event added while nothing is
  /// listening. A second subscription throws at runtime — today there is exactly one,
  /// wired once at startup.
  Stream<PushTap> get taps;

  /// Ids of messages whose banner the user swiped away.
  ///
  /// A tap never appears here: the plugin documents that dismissing via a tap or
  /// `cancel` is not reported as a dismissal, so one press cannot produce both an
  /// `opened` and a `dismissed`.
  ///
  /// Only banners *this app* drew can be reported — foreground or background, since
  /// both are posted through the plugin — and only while the process is still alive
  /// to receive the callback. A tray entry FCM drew itself was never posted through
  /// the plugin, and a swipe after the process has been killed reaches no isolate at
  /// all; both cases leave this stream silent rather than reporting late.
  ///
  /// Android only: the plugin reports a swipe through `dismissIsolate: main`, which
  /// exists on `AndroidNotificationDetails` alone. On iOS this stream never emits:
  /// `show` posts a default `DarwinNotificationDetails` with no `customDismissAction`
  /// category, so there is no route for a dismissal to take.
  ///
  /// Single-subscription, for the same reason [taps] is: whatever wires one up also
  /// wires up [taps], so the same one-listener rule applies here too.
  Stream<String> get dismissals;

  Future<void> dispose();
}
