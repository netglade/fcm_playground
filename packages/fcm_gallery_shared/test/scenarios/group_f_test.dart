import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `data` block of [scenario]'s template. Reaches through with `!`: group F builds
/// every one of its features client-side out of `data`, so a missing block is a broken
/// entry.
Map<Object?, Object?> dataOf(Scenario scenario) =>
    scenario.payloadTemplate['data']! as Map<Object?, Object?>;

/// The `android.notification` block of [scenario]'s template.
Map<Object?, Object?> androidNotificationOf(Scenario scenario) {
  final android = scenario.payloadTemplate['android']! as Map<Object?, Object?>;

  return android['notification']! as Map<Object?, Object?>;
}

/// The one scenario in group F carrying [id].
Scenario scenarioF(String id) => groupF.firstWhere((s) => s.id == id);

void main() {
  group('group F', () {
    test('offers all nine interaction scenarios, in order', () {
      expect(groupF.map((s) => s.id), [
        'f1_actions',
        'f2_inline_reply',
        'f3_deeplink_foreground',
        'f4_deeplink_background',
        'f5_deeplink_killed',
        'f6_delete_intent',
        'f7_ongoing',
        'f8_full_screen_intent',
        'f9_trampoline',
      ]);
    });

    test('eight of the nine are still blocked on interaction work', () {
      // `contains(interaction)` alone passes on an entry that ALSO carries
      // channels or styles, which would file this group's work under the wrong
      // sub-project. So needs are pinned exactly, and the literal counts back
      // the words: f1 was unblocked by the notification-actions cycle, and the
      // other eight are the sub-projects still to come.
      expect(groupF, hasLength(9));

      const expected = {
        'f1_actions': <ScenarioNeed>[],
        'f2_inline_reply': [ScenarioNeed.interaction],
        'f3_deeplink_foreground': [ScenarioNeed.interaction],
        'f4_deeplink_background': [ScenarioNeed.interaction],
        'f5_deeplink_killed': [ScenarioNeed.interaction],
        'f6_delete_intent': [ScenarioNeed.interaction],
        'f7_ongoing': [ScenarioNeed.interaction],
        'f8_full_screen_intent': [
          ScenarioNeed.interaction,
          ScenarioNeed.externalApproval,
        ],
        'f9_trampoline': [ScenarioNeed.interaction],
      };

      for (final scenario in groupF) {
        final needs = expected[scenario.id]!;
        expect(scenario.needs, needs, reason: scenario.id);
        // f1 is the one entry unblocked this cycle: isSupported flips to true
        // exactly when its needs list is empty, so drive the expectation from
        // the same map rather than special-casing an id here.
        expect(scenario.isSupported, needs.isEmpty, reason: scenario.id);
      }
    });

    test('f5 alone is about the killed app, and is arranged to be sendable', () {
      // Asserted here as well as gallery-wide, so this file says which of the nine
      // may carry the flag. Pinning the other eight to false is what catches it
      // spreading to entries observable in every app state.
      final killed = scenarioF('f5_deeplink_killed');

      expect(killed.requiresKilledApp, isTrue);
      expect(killed.needs, [ScenarioNeed.interaction]);
      expect(killed.defaultDelaySeconds, greaterThan(0));

      for (final scenario in groupF.where((s) => s.id != killed.id)) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
      }
    });

    test('f8 also needs a permission Android 14+ may refuse', () {
      // contains('USE_FULL_SCREEN_INTENT') alone is satisfied by prose denying the
      // requirement, so the directional phrases are pinned too: who grants it, and
      // what this app gets instead.
      final fullScreen = scenarioF('f8_full_screen_intent');

      expect(fullScreen.needs, contains(ScenarioNeed.externalApproval));
      expect(fullScreen.expectation, contains('USE_FULL_SCREEN_INTENT'));
      expect(fullScreen.expectation, contains('Android 14+ grants'));
      expect(fullScreen.expectation, contains('degraded heads-up'));

      // No such channel exists yet, but the template has to name it or there is
      // nothing for the call-style notification to be posted to.
      expect(androidNotificationOf(fullScreen)['channel_id'], 'calls');
    });

    test('the three deep-link scenarios carry three distinct routes', () {
      // isNotNull is far too weak: '', 'true' and a bare number all pass it and none
      // routes anywhere. Each link is a non-blank absolute path, and the three must
      // differ or the foreground, background and killed paths are indistinguishable.
      const ids = [
        'f3_deeplink_foreground',
        'f4_deeplink_background',
        'f5_deeplink_killed',
      ];

      final links = <String>[];
      for (final id in ids) {
        final link = dataOf(scenarioF(id))['deep_link'];
        expect(link, isA<String>(), reason: id);

        final route = link! as String;
        expect(route, startsWith('/'), reason: id);
        expect(route.trim().length, greaterThan(1), reason: id);
        links.add(route);
      }

      expect(links.toSet(), hasLength(ids.length), reason: '$links');
    });

    test('f5 names getInitialMessage and says it is where the bugs are', () {
      // The API name alone would pass on a description that made no point about
      // where the bugs are, so both halves are pinned.
      final killed = scenarioF('f5_deeplink_killed');

      expect(killed.description, contains('getInitialMessage'));
      expect(
        killed.description,
        contains('commonest source of deep-link bugs'),
      );
    });

    test('every client-side feature is carried in data, as strings', () {
      // FCM has no field for any of this, so all nine hand it to the client through
      // `data` — a map<string, string>, so a bare `true` is a parse failure.
      // Non-emptiness catches an entry that gives the client nothing to act on.
      for (final scenario in groupF) {
        final data = dataOf(scenario);
        expect(data, isNotEmpty, reason: scenario.id);

        for (final entry in data.entries) {
          final where = '${scenario.id}.${entry.key}';
          expect(entry.value, isA<String>(), reason: where);
          expect(entry.value! as String, isNotEmpty, reason: where);
        }
      }
    });

    test('f9 states that the failure is the demonstration', () {
      // contains('fail') alone is satisfied by 'should not fail', so both the version
      // that banned it and the statement that the error is the result are pinned.
      final trampoline = scenarioF('f9_trampoline');

      expect(trampoline.expectation, contains('Android 12'));
      expect(
        trampoline.expectation,
        contains('the error, not a working route'),
      );
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupF) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
