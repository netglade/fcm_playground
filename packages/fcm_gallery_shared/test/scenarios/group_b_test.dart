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

    test('b5 expects NOT to arrive, and says so', () {
      // A scenario whose success is a non-delivery has to say so. `contains('not')`
      // would not do: the word "nothing" satisfies it accidentally.
      final forceStopped = groupB.firstWhere((s) => s.id == 'b5_force_stopped');

      expect(forceStopped.expectation, contains('nothing'));
      expect(forceStopped.expectation, contains('force-stopped'));
    });

    test('every manual-step scenario spells out the step', () {
      for (final scenario in groupB) {
        if (scenario.needs.contains(ScenarioNeed.manualStep)) {
          expect(scenario.manualSteps, isNotNull, reason: scenario.id);
          expect(scenario.manualSteps!.trim(), isNotEmpty, reason: scenario.id);
        }
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupB) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
