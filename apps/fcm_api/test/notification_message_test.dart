import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Map<String, Object?> messageFor(NotificationDraft draft) {
    final built = NotificationMessage(
      token: 'device-token',
      draft: draft,
      payloadId: 'api-1754812345678901',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    ).toJson();

    return built['message']! as Map<String, Object?>;
  }

  const draft = NotificationDraft(
    title: 'Build finished',
    body: 'main #128 passed',
    data: {'event': 'build_finished'},
  );

  group('NotificationMessage.toJson', () {
    test('wraps the message the way the v1 endpoint requires', () {
      final built = NotificationMessage(
        token: 'device-token',
        draft: draft,
        payloadId: 'api-1',
        sentAt: DateTime.utc(2026),
      ).toJson();

      expect(built.keys, ['message']);
    });

    test('targets the supplied token', () {
      expect(messageFor(draft)['token'], 'device-token');
    });

    test('sends a notification block so a backgrounded app still shows it', () {
      expect(messageFor(draft)['notification'], {
        'title': 'Build finished',
        'body': 'main #128 passed',
      });
    });

    test('asks Android for high priority, so it arrives while you watch', () {
      expect(messageFor(draft)['android'], {'priority': 'high'});
    });

    test('repeats the four keys PushMessageParser reads inside data', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data['id'], 'api-1754812345678901');
      expect(data['title'], 'Build finished');
      expect(data['body'], 'main #128 passed');
      expect(data['sentAt'], '2026-08-11T09:12:03.000Z');
    });

    test('passes the extra data keys through untouched', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data['event'], 'build_finished');
    });

    test('still carries the four required keys when data is empty', () {
      final data =
          messageFor(
                const NotificationDraft(title: 'Hi', body: 'There'),
              )['data']!
              as Map<String, Object?>;

      expect(data.keys, containsAll(['id', 'title', 'body', 'sentAt']));
      expect(data, hasLength(4));
    });

    test('writes every data value as a string, as FCM requires', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data.values, everyElement(isA<String>()));
    });
  });
}
