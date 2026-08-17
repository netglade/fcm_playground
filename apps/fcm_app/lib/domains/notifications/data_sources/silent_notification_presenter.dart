import 'package:core/core.dart';

import 'notification_presenter.dart';

/// A [NotificationPresenter] that never shows anything.
///
/// The default in widget tests, and the fallback when the notification plugin
/// fails to initialise — a broken plugin should cost the banners, not the app.
/// The same role `DisabledPushSource` plays on the receiving side.
class SilentNotificationPresenter implements NotificationPresenter {
  const SilentNotificationPresenter();

  @override
  Future<void> initialize() => Future<void>.value();

  @override
  Future<void> show(PushMessage _) => Future<void>.value();

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> dispose() => Future<void>.value();
}
