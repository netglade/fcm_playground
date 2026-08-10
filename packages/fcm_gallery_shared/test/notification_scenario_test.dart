import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('notificationGallery', () {
    test('ids are unique, so a scenario can be addressed by id', () {
      final ids = notificationGallery.map((s) => s.id).toSet();

      expect(ids, hasLength(notificationGallery.length));
    });

    test('every scenario has a label and a description to show', () {
      for (final scenario in notificationGallery) {
        expect(scenario.label, isNotEmpty, reason: scenario.id);
        expect(scenario.description, isNotEmpty, reason: scenario.id);
      }
    });

    test('covers every event exactly once, so the gallery is a full tour', () {
      final events = notificationGallery.map((s) => s.draft.event).toList();

      expect(events, unorderedEquals(NotificationEvent.values));
    });

    test('the silent scenario is the one that sends data only', () {
      final silent = notificationGallery.firstWhere(
        (s) => s.id == 'silent-sync',
      );

      expect(silent.draft.delivery.asNotification, isFalse);
    });

    test(
      'the chat scenario carries a deep link, exercising extra data keys',
      () {
        final chat = notificationGallery.firstWhere(
          (s) => s.id == 'chat-message',
        );

        expect(chat.draft.data, containsPair('deepLink', '/chats/7'));
      },
    );

    test('the promo scenario is normal priority, not everything is urgent', () {
      final promo = notificationGallery.firstWhere((s) => s.id == 'promo');

      expect(promo.draft.delivery.priority, NotificationPriority.normal);
    });
  });
}
