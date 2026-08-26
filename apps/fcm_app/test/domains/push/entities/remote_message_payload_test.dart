import 'package:fcm_app/domains/push/entities/remote_message_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('remoteMessageToPayload', () {
    test('takes the title and body from the notification block', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(
          messageId: 'msg-1',
          notification: RemoteNotification(
            title: 'Build finished',
            body: 'Release 1.0.0 is ready.',
          ),
        ),
      );

      expect(payload['id'], 'msg-1');
      expect(payload['title'], 'Build finished');
      expect(payload['body'], 'Release 1.0.0 is ready.');
    });

    test('lets the data map win, so a data-only push is fully supported', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(
          messageId: 'from-fcm',
          data: {'id': 'from-data', 'title': 'Data title'},
          notification: RemoteNotification(title: 'Notification title'),
        ),
      );

      expect(payload['id'], 'from-data');
      expect(payload['title'], 'Data title');
    });

    test('passes extra data keys through untouched', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(data: {'deepLink': '/builds/42'}),
      );

      expect(payload['deepLink'], '/builds/42');
    });

    test('normalises sentTime to a UTC ISO-8601 string', () {
      final payload = remoteMessageToPayload(
        RemoteMessage(sentTime: DateTime.utc(2026, 8, 11, 9, 30)),
      );

      expect(payload['sentAt'], '2026-08-11T09:30:00.000Z');
    });

    test('falls back to now when the message carries no sentTime', () {
      final before = DateTime.now().toUtc();

      final payload = remoteMessageToPayload(const RemoteMessage());

      final sentAt = DateTime.parse(payload['sentAt']! as String);
      expect(sentAt.isBefore(before), isFalse);
      expect(sentAt.isUtc, isTrue);
    });

    test(
      'substitutes blanks rather than nulls, so the parser names the field',
      () {
        final payload = remoteMessageToPayload(const RemoteMessage());

        expect(payload['id'], '');
        expect(payload['title'], '');
        expect(payload['body'], '');
      },
    );

    test('carries the channel the notification block names', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'Title',
            body: 'Body',
            android: AndroidNotification(channelId: 'importance_low'),
          ),
        ),
      );

      expect(payload, containsPair(pushChannelKey, 'importance_low'));
    });

    test('omits the channel for a data-only push', () {
      // Nothing to carry, and a blank would look like a channel named ''.
      final payload = remoteMessageToPayload(
        const RemoteMessage(data: {'event': 'sync'}),
      );

      expect(payload, isNot(contains(pushChannelKey)));
    });

    test(
      'lets data win over the notification block, as every other field does',
      () {
        final payload = remoteMessageToPayload(
          const RemoteMessage(
            notification: RemoteNotification(
              title: 'Title',
              body: 'Body',
              android: AndroidNotification(channelId: 'importance_low'),
            ),
            data: {pushChannelKey: 'alarms'},
          ),
        );

        expect(payload[pushChannelKey], 'alarms');
      },
    );
  });
}
