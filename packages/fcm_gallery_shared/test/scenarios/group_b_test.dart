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

    test('b3 is the one that drives the delayed-send work', () {
      final killed = groupB.firstWhere((s) => s.id == 'b3_killed');

      expect(killed.needs, contains(ScenarioNeed.delayedSend));
      expect(killed.requiresKilledApp, isTrue);
      expect(killed.defaultDelaySeconds, greaterThan(0));
    });

    test('b5 expects NOT to arrive, and says so', () {
      // A scenario whose success is a non-delivery has to state that, or it
      // reads as a broken test.
      final forceStopped = groupB.firstWhere((s) => s.id == 'b5_force_stopped');

      expect(forceStopped.expectation, contains('not'));
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
