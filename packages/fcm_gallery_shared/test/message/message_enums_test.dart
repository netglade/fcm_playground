import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('wire names', () {
    test('AndroidMessagePriority matches FCM spelling', () {
      expect(AndroidMessagePriority.values.map((value) => value.wireName), [
        'NORMAL',
        'HIGH',
      ]);
    });

    test('AndroidNotificationPriority matches FCM spelling', () {
      expect(
        AndroidNotificationPriority.values.map((value) => value.wireName),
        [
          'PRIORITY_UNSPECIFIED',
          'PRIORITY_MIN',
          'PRIORITY_LOW',
          'PRIORITY_DEFAULT',
          'PRIORITY_HIGH',
          'PRIORITY_MAX',
        ],
      );
    });

    test('NotificationVisibility matches FCM spelling', () {
      expect(NotificationVisibility.values.map((value) => value.wireName), [
        'VISIBILITY_UNSPECIFIED',
        'PRIVATE',
        'PUBLIC',
        'SECRET',
      ]);
    });

    test('NotificationProxy matches FCM spelling', () {
      expect(NotificationProxy.values.map((value) => value.wireName), [
        'PROXY_UNSPECIFIED',
        'ALLOW',
        'DENY',
        'IF_PRIORITY_LOWERED',
      ]);
    });

    test('every wire name is unique within its enum', () {
      for (final names in [
        AndroidMessagePriority.values.map((value) => value.wireName),
        AndroidNotificationPriority.values.map((value) => value.wireName),
        NotificationVisibility.values.map((value) => value.wireName),
        NotificationProxy.values.map((value) => value.wireName),
      ]) {
        expect(names.toSet(), hasLength(names.length));
      }
    });
  });

  group('JsonObjectReader.enumValue', () {
    test('maps a known wire name', () {
      final reader = JsonObjectReader({'priority': 'HIGH'}, path: 'message');

      expect(
        reader.enumValue(
          'priority',
          AndroidMessagePriority.values,
          (value) => value.wireName,
        ),
        AndroidMessagePriority.high,
      );
    });

    test('rejects an unrecognised value, indistinguishable from a typo', () {
      final reader = JsonObjectReader({'priority': 'URGENT'}, path: 'message');

      expect(
        () => reader.enumValue(
          'priority',
          AndroidMessagePriority.values,
          (value) => value.wireName,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('message.priority: unknown value "URGENT"'),
          ),
        ),
      );
    });
  });
}
