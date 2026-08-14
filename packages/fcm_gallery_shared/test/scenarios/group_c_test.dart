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
      // NOT "differ only in priority" — they also differ in title and body, so
      // that name would be false. What matters is that the two spellings FCM
      // accepts are both present and correctly cased: 'high' or 'Normal' is a
      // 400 from Google, and nothing local would catch it.
      final high = groupC.firstWhere((s) => s.id == 'c1_priority_high');
      final normal = groupC.firstWhere((s) => s.id == 'c2_priority_normal');

      expect((high.payloadTemplate['android']! as Map)['priority'], 'HIGH');
      expect((normal.payloadTemplate['android']! as Map)['priority'], 'NORMAL');
    });

    test('both ttl scenarios use a proto duration, not a number', () {
      // FCM wants "0s", not 0. A bare number is a 400 from Google.
      //
      // Matched against the full duration shape rather than endsWith('s'):
      // '86400 seconds', '0 s' and even 'abcs' all end in s, so that check
      // would pass on three spellings FCM rejects.
      final duration = RegExp(r'^\d+(\.\d+)?s$');

      for (final id in const ['c3_ttl_zero', 'c4_ttl_long']) {
        final ttl =
            (groupC.firstWhere((s) => s.id == id).payloadTemplate['android']!
                as Map)['ttl'];
        expect(ttl, isA<String>(), reason: id);
        expect(ttl, matches(duration), reason: id);
      }
    });

    test('the adb scenarios carry a runnable command, not just a keyword', () {
      // contains('force-idle') alone would pass on prose that merely mentioned
      // the flag. These are commands a user copies verbatim, so the assertion
      // pins the whole invocation.
      expect(
        groupC.firstWhere((s) => s.id == 'c6_doze_test').manualSteps,
        contains('adb shell dumpsys deviceidle force-idle'),
      );
      expect(
        groupC.firstWhere((s) => s.id == 'c7_standby_bucket').manualSteps,
        contains('adb shell am set-standby-bucket cz.netglade.fcm_app'),
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
