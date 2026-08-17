import 'package:fcm_app/domains/sandbox/entities/notification_send_exception.dart';
import 'package:fcm_app/domains/sandbox/entities/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] driven by the test rather than by the API.
class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.failure});

  /// Thrown by [send] when set.
  final NotificationSendException? failure;

  /// Every request handed to [send], so the payload can be asserted.
  final sent = <SendMessageRequest>[];

  /// Every response [send] answered with, in order, so a test can name the trace
  /// id of one particular send.
  final responses = <SendMessageResponse>[];

  /// What [send] answers, apart from the trace id.
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

    // A fresh trace id per send, as the API mints one per send: a constant would let
    // a widget report against the *previous* send's id and still pass.
    final answer = SendMessageResponse(
      messageId: response.messageId,
      sentAt: response.sentAt,
      traceId: 'tr-${sent.length}',
    );
    responses.add(answer);

    return answer;
  }
}
