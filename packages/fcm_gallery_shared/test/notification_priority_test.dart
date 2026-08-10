import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationPriority', () {
    test('every value round-trips through its wire name', () {
      for (final priority in NotificationPriority.values) {
        expect(NotificationPriority.fromWireName(priority.wireName), priority);
      }
    });

    test('wire names match the FCM vocabulary', () {
      expect(NotificationPriority.high.wireName, 'high');
      expect(NotificationPriority.normal.wireName, 'normal');
    });

    test('an unrecognised wire name resolves to null', () {
      expect(NotificationPriority.fromWireName('urgent'), isNull);
    });
  });
}
