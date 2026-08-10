import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationDelivery', () {
    test('defaults to a visible, high-priority notification', () {
      const delivery = NotificationDelivery();

      expect(delivery.asNotification, isTrue);
      expect(delivery.priority, NotificationPriority.high);
    });

    test('round-trips through JSON', () {
      const delivery = NotificationDelivery(
        asNotification: false,
        priority: NotificationPriority.normal,
      );

      expect(NotificationDelivery.fromJson(delivery.toJson()), delivery);
    });

    test('copyWith replaces one field and leaves the other alone', () {
      const delivery = NotificationDelivery();

      final silent = delivery.copyWith(asNotification: false);

      expect(silent.asNotification, isFalse);
      expect(silent.priority, NotificationPriority.high);
    });

    test('an unknown priority is a format error, not a silent default', () {
      expect(
        () => NotificationDelivery.fromJson({
          'asNotification': true,
          'priority': 'urgent',
        }),
        throwsFormatException,
      );
    });
  });
}
