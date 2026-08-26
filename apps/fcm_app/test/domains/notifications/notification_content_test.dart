import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/push/push_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PushMessage message({String id = 'msg-1', String? tag}) => PushMessage(
    id: id,
    title: 'Build 128',
    body: 'Running…',
    sentAt: DateTime.utc(2026, 8, 24, 9),
    tag: tag,
  );

  group('notificationIdFor', () {
    test('is stable, so re-showing a message replaces its banner', () {
      expect(
        notificationIdFor('api-1754812345678901'),
        notificationIdFor('api-1754812345678901'),
      );
    });

    test('separates different messages', () {
      expect(notificationIdFor('api-1'), isNot(notificationIdFor('api-2')));
    });

    test('stays within a 32-bit signed int, which Android requires', () {
      for (final id in ['', 'a', 'api-1754812345678901', 'x' * 500]) {
        final value = notificationIdFor(id);

        expect(value, greaterThanOrEqualTo(0), reason: id);
        expect(value, lessThanOrEqualTo(2147483647), reason: id);
      }
    });
  });

  group('notificationIdOf', () {
    test('keys the notification on the tag when there is one', () {
      expect(
        notificationIdOf(message(id: 'a', tag: 'build-128')),
        notificationIdOf(message(id: 'b', tag: 'build-128')),
        reason:
            'two sends sharing a tag are the same notification being updated, '
            'which is the whole of what g2 demonstrates',
      );
    });

    test('keys on the message id when there is no tag', () {
      expect(
        notificationIdOf(message(id: 'a')),
        isNot(notificationIdOf(message(id: 'b'))),
      );
    });

    test('keeps a tagged and an untagged message apart', () {
      expect(
        notificationIdOf(message(id: 'a', tag: 'build-128')),
        isNot(notificationIdOf(message(id: 'a'))),
      );
    });
  });

  group('the channel', () {
    test('has an id, a name and a description', () {
      expect(notificationChannelId, isNotEmpty);
      expect(notificationChannelName.trim(), isNotEmpty);
      expect(notificationChannelDescription.trim(), isNotEmpty);
    });

    test('uses the id the Android manifest points FCM at', () {
      expect(notificationChannelId, 'fcm_sample_high');
    });
  });
}
