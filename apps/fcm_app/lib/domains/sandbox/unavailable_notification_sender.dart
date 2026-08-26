import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';

/// A [NotificationSender] used when Firebase failed to start: it always fails
/// with the reason, so the app never special-cases a null sender.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  final String reason;

  @override
  Future<SendMessageResponse> send(SendMessageRequest _) =>
      Future.error(NotificationSendException(reason));
}
