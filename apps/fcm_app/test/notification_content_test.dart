import 'package:fcm_app/notifications/notification_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
