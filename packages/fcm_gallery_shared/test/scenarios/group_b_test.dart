import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('group B', () {
    test('offers all six application-state scenarios, in order', () {
      expect(groupB.map((s) => s.id), [
        'b1_foreground',
        'b2_background',
        'b3_killed',
        'b4_after_reboot',
        'b5_force_stopped',
        'b6_token_refresh',
      ]);
    });

    test('b3 works today, now that delayed sending is arranged', () {
      final killed = groupB.firstWhere((s) => s.id == 'b3_killed');

      expect(killed.needs, isEmpty);
      expect(killed.requiresKilledApp, isTrue);
      expect(killed.defaultDelaySeconds, greaterThan(0));
    });

    // The prose assertions that used to live here — what b5's expectation says,
    // and that every manual-step scenario spells one out — moved to
    // apps/fcm_app/test/i18n/scenario_prose_test.dart: this package has no access
    // to the translations that prose now lives in.

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupB) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
