import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';

/// A [NotificationSender] that always fails with the reason it cannot work.
///
/// Used when Firebase failed to start: there will be no registration token, so
/// there is nowhere to send. The reason travels to the UI instead of the app
/// special-casing a null sender — exactly as `DisabledPushSource` does on the
/// receiving side.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  /// Why sending is unavailable.
  final String reason;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest _) =>
      Future.error(NotificationSendException(reason));
}
