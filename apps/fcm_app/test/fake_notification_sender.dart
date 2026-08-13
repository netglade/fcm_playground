import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] driven by the test rather than by the API.
class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.failure});

  /// Thrown by [send] when set.
  final NotificationSendException? failure;

  /// Every request handed to [send], so the payload can be asserted.
  final sent = <SendMessageRequest>[];

  /// Returned by [send] on success.
  static final response = SendMessageResponse(
    messageId: 'projects/p/messages/0:17',
    sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    traceId: 'tr-1',
  );

  @override
  Future<SendMessageResponse> send(SendMessageRequest request) async {
    sent.add(request);
    if (failure case final failure?) {
      throw failure;
    }

    return response;
  }
}
