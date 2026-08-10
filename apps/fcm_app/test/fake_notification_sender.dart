import 'package:fcm_app/sandbox/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] the tests drive directly.
///
/// Exists for the same reason `FakePushSource` does: `cloud_functions` must
/// never be constructed in a widget test.
class FakeNotificationSender implements NotificationSender {
  SendNotificationRequest? lastRequest;
  Object? failWith;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    lastRequest = request;
    if (failWith case final failure?) {
      throw failure;
    }

    return SendNotificationResponse(
      messageId: 'projects/fcm-sandbox-770fa/messages/42',
      payloadId: 'sandbox-1',
      sentAt: DateTime.utc(2026, 8, 10, 9, 30),
    );
  }
}
