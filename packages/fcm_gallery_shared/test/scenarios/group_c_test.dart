import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('group C', () {
    test(
      'offers all seven priority and delivery-window scenarios, in order',
      () {
        expect(groupC.map((s) => s.id), [
          'c1_priority_high',
          'c2_priority_normal',
          'c3_ttl_zero',
          'c4_ttl_long',
          'c5_collapse_key',
          'c6_doze_test',
          'c7_standby_bucket',
        ]);
      },
    );

    test('the priority pair sends the two values FCM accepts', () {
      // NOT "differ only in priority": they also differ in title and body. What
      // matters is that both spellings FCM accepts are present and correctly cased —
      // 'high' or 'Normal' is a 400 nothing local would catch.
      final high = groupC.firstWhere((s) => s.id == 'c1_priority_high');
      final normal = groupC.firstWhere((s) => s.id == 'c2_priority_normal');

      expect((high.payloadTemplate['android']! as Map)['priority'], 'HIGH');
      expect((normal.payloadTemplate['android']! as Map)['priority'], 'NORMAL');
    });

    test('both ttl scenarios use a proto duration, not a number', () {
      // FCM wants "0s", not 0. Matched against the full duration shape rather than
      // endsWith('s'), which '86400 seconds', '0 s' and 'abcs' all satisfy.
      final duration = RegExp(r'^\d+(\.\d+)?s$');

      for (final id in const ['c3_ttl_zero', 'c4_ttl_long']) {
        final ttl =
            (groupC.firstWhere((s) => s.id == id).payloadTemplate['android']!
                as Map)['ttl'];
        expect(ttl, isA<String>(), reason: id);
        expect(ttl, matches(duration), reason: id);
      }
    });

    // The adb-command wording moved to
    // apps/fcm_app/test/i18n/scenario_prose_test.dart along with every other
    // prose assertion: this package has no access to the translations.

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupC) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
