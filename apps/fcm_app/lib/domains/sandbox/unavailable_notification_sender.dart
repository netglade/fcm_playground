import 'package:fcm_app/domains/sandbox/notification_send_exception.dart';
import 'package:fcm_app/domains/sandbox/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] used when Firebase failed to start: it always fails
/// with the reason, so the app never special-cases a null sender.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  final String reason;

  @override
  Future<SendMessageResponse> send(SendMessageRequest _) =>
      Future.error(NotificationSendException(reason));
}
