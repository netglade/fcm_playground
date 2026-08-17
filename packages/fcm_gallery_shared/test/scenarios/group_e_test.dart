import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `notification` block of [scenario]'s template. Reaches through with `!`, so a
/// missing block fails the test rather than reading as null.
Map<Object?, Object?> notificationOf(Scenario scenario) =>
    scenario.payloadTemplate['notification']! as Map<Object?, Object?>;

/// The `android.notification` block of [scenario]'s template.
Map<Object?, Object?> androidNotificationOf(Scenario scenario) {
  final android = scenario.payloadTemplate['android']! as Map<Object?, Object?>;

  return android['notification']! as Map<Object?, Object?>;
}

/// The one scenario in group E carrying [id].
Scenario scenarioE(String id) => groupE.firstWhere((s) => s.id == id);

void main() {
  group('group E', () {
    test('offers all eleven appearance scenarios, in order', () {
      expect(groupE.map((s) => s.id), [
        'e1_long_text',
        'e2_image_remote',
        'e3_image_local',
        'e4_image_huge',
        'e5_image_404',
        'e6_large_icon',
        'e7_inbox_style',
        'e8_messaging_style',
        'e9_progress',
        'e10_color_and_icon',
        'e11_emoji_rtl',
      ]);
    });

    test('exactly five of the eleven work today; the six others need styles', () {
      // Two halves of one claim: `isSupported` only reads "needs is empty", so an
      // entry filed under the wrong need would still be absent from this list and
      // look correct. Hence every unsupported entry's needs pinned to [styles].
      expect(groupE, hasLength(11));
      expect(groupE.where((s) => s.isSupported).map((s) => s.id), [
        'e2_image_remote',
        'e4_image_huge',
        'e5_image_404',
        'e10_color_and_icon',
        'e11_emoji_rtl',
      ]);

      for (final scenario in groupE.where((s) => !s.isSupported)) {
        expect(scenario.needs, [ScenarioNeed.styles], reason: scenario.id);
      }
    });

    test('nothing here is about the killed app', () {
      // Appearance is observable in any app state, so the flag would only mislead —
      // and would drag in the delayedSend this group has no use for.
      for (final scenario in groupE) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.needs, isNot(contains(ScenarioNeed.delayedSend)));
      }
    });

    test('the long-text body is genuinely long, with diacritics', () {
      final body = notificationOf(scenarioE('e1_long_text'))['body']! as String;

      expect(body.length, greaterThan(600));
      expect(body, contains('ě'));
    });

    test('e2 says Android renders the image and iOS needs an extension', () {
      // contains('Notification Service Extension') alone would pass on prose that
      // denied the requirement, so both halves of the phrase are pinned.
      final remote = scenarioE('e2_image_remote');

      expect(remote.expectation, contains('Android does this natively'));
      expect(
        remote.expectation,
        contains('iOS requires a Notification Service Extension'),
      );
      expect(notificationOf(remote)['image'], isNotNull);
    });

    test(
      'e5 points at a host that cannot resolve, not just a URL naming one',
      () {
        // contains('example.test') is satisfied by a resolvable URL carrying it as a
        // query parameter, so the authority itself is parsed and compared.
        final image =
            notificationOf(scenarioE('e5_image_404'))['image']! as String;
        final url = Uri.parse(image);

        expect(url.host, 'example.test', reason: '.test can never resolve');
        expect(url.scheme, 'https');
        expect(url.path, isNotEmpty);
      },
    );

    test('e10 pins a #rrggbb colour and a monochrome status-bar icon', () {
      // FCM wants exactly six hex digits: #4285f4ff and 4285f4 are both 400s
      // from Google, and both would satisfy a startsWith('#') check.
      final notification = androidNotificationOf(
        scenarioE('e10_color_and_icon'),
      );

      expect(notification['color'], matches(RegExp(r'^#[0-9a-fA-F]{6}$')));

      // A drawable resource name, and by the ic_stat_ convention a flat monochrome
      // one — the full-colour launcher icon is what produces the Xiaomi white square.
      final icon = notification['icon']! as String;
      expect(icon, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
      expect(icon, startsWith('ic_stat_'));
      expect(
        scenarioE('e10_color_and_icon').expectation,
        contains('monochrome'),
      );
    });

    test('the client-rendered styles pass their numbers as strings', () {
      // FCM's data map is map<string, string>, so 40 is a parse failure rather than a
      // rounding problem.
      for (final scenario in groupE) {
        final data = scenario.payloadTemplate['data'];
        if (data == null) continue;

        for (final entry in (data as Map<Object?, Object?>).entries) {
          expect(
            entry.value,
            isA<String>(),
            reason: '${scenario.id}.${entry.key}',
          );
        }
      }

      final progress =
          scenarioE('e9_progress').payloadTemplate['data']!
              as Map<Object?, Object?>;
      expect(progress['progress'], '40');
      expect(progress['max'], '100');
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupE) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
