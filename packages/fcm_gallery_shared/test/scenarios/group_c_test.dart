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

    test('the two priority scenarios differ only in priority', () {
      final high = groupC.firstWhere((s) => s.id == 'c1_priority_high');
      final normal = groupC.firstWhere((s) => s.id == 'c2_priority_normal');

      expect((high.payloadTemplate['android']! as Map)['priority'], 'HIGH');
      expect((normal.payloadTemplate['android']! as Map)['priority'], 'NORMAL');
    });

    test('both ttl scenarios use a proto duration, not a number', () {
      // FCM wants "0s", not 0. A bare number is a 400 from Google.
      for (final id in const ['c3_ttl_zero', 'c4_ttl_long']) {
        final ttl =
            (groupC.firstWhere((s) => s.id == id).payloadTemplate['android']!
                as Map)['ttl'];
        expect(ttl, isA<String>(), reason: id);
        expect(ttl, endsWith('s'), reason: id);
      }
    });

    test('the adb scenarios carry the exact command', () {
      expect(
        groupC.firstWhere((s) => s.id == 'c6_doze_test').manualSteps,
        contains('force-idle'),
      );
      expect(
        groupC.firstWhere((s) => s.id == 'c7_standby_bucket').manualSteps,
        contains('set-standby-bucket'),
      );
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupC) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
