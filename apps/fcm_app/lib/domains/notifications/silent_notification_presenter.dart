import 'package:core/core.dart';

import '../push/push_tap.dart';
import 'notification_presenter.dart';

/// A [NotificationPresenter] that never shows anything — the default in widget
/// tests, and the fallback when the notification plugin fails to initialise.
class SilentNotificationPresenter implements NotificationPresenter {
  const SilentNotificationPresenter();

  @override
  Future<void> initialize() => Future<void>.value();

  @override
  Future<void> show(PushMessage _) => Future<void>.value();

  @override
  Stream<PushTap> get taps => const Stream.empty();

  @override
  Stream<String> get dismissals => const Stream.empty();

  @override
  Future<void> clearAll() => Future<void>.value();

  @override
  Future<void> dispose() => Future<void>.value();
}
