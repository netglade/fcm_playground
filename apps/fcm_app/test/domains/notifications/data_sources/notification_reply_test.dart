import 'package:fcm_app/domains/notifications/data_sources/notification_reply.dart';
import 'package:fcm_app/domains/push/entities/pending_reply.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('replyFrom', () {
    test(
      'takes the message id from the payload and the text from the input',
      () {
        final reply = replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'msg-1',
            actionId: 'reply',
            input: 'ready when you are',
          ),
        );

        expect(reply, const PendingReply('msg-1', 'ready when you are'));
      },
    );

    test('keeps an empty reply, which is a thing a user can send', () {
      final reply = replyFrom(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          payload: 'msg-1',
          actionId: 'reply',
          input: '',
        ),
      );

      expect(reply?.text, '');
    });

    test('ignores a response carrying no input at all', () {
      expect(
        replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'msg-1',
            actionId: 'mute',
          ),
        ),
        isNull,
        reason:
            'a plain action reaches the main isolate and is answered there; '
            'this isolate only exists for the typed kind',
      );
    });

    test('ignores a response with no payload to attach the reply to', () {
      expect(
        replyFrom(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: 'reply',
            input: 'orphan',
          ),
        ),
        isNull,
      );
    });
  });
}
