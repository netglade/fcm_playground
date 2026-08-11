import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('notificationGallery', () {
    test('offers the four presets the Sandbox shows', () {
      expect(notificationGallery, hasLength(4));
    });

    test('gives every scenario a unique id', () {
      final ids = notificationGallery.map((scenario) => scenario.id).toSet();

      expect(ids, hasLength(notificationGallery.length));
    });

    test('gives every scenario a non-blank label and description', () {
      for (final scenario in notificationGallery) {
        expect(scenario.label.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test('every preset validates clean, so one tap is always sendable', () {
      const validator = NotificationDraftValidator();

      for (final scenario in notificationGallery) {
        expect(
          validator.validate(scenario.draft),
          isEmpty,
          reason: '${scenario.id} should need no editing',
        );
      }
    });

    test('covers both the with-data and the without-data path', () {
      final withData = notificationGallery.where(
        (scenario) => scenario.draft.data.isNotEmpty,
      );
      final withoutData = notificationGallery.where(
        (scenario) => scenario.draft.data.isEmpty,
      );

      expect(withData, isNotEmpty);
      expect(withoutData, isNotEmpty);
    });
  });
}
