import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_sender.dart';

/// The [NotificationSender] used when Firebase never started.
///
/// The counterpart of `DisabledPushSource`: the sandbox still renders, the send
/// button is disabled, and the reason is the one already shown in the setup
/// banner rather than a second, different explanation.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  /// Why sending is impossible.
  final String reason;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) =>
      Future.error(StateError(reason));
}
