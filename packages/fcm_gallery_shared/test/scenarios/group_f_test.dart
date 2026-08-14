import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `data` block of [scenario]'s template.
///
/// Reaches through with `!`, so an entry carrying no data block fails the test
/// rather than silently reading as null — group F builds every one of its
/// features client-side out of `data`, so a missing block is a broken entry.
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

    test('all nine are blocked on interaction work and nothing unrelated', () {
      // `contains(interaction)` alone is not enough: it passes on an entry that
      // ALSO carries channels or styles, which would file this group's work
      // under the wrong sub-project and make "which scenarios does the
      // interaction work unblock?" answer wrongly. Every entry's needs are
      // therefore pinned exactly, and hasLength(9) is what backs the words
      // "all nine" — without it the name claims a total nothing checks.
      expect(groupF, hasLength(9));

      const expected = {
        'f1_actions': [ScenarioNeed.interaction],
        'f2_inline_reply': [ScenarioNeed.interaction],
        'f3_deeplink_foreground': [ScenarioNeed.interaction],
        'f4_deeplink_background': [ScenarioNeed.interaction],
        'f5_deeplink_killed': [
          ScenarioNeed.interaction,
          ScenarioNeed.delayedSend,
        ],
        'f6_delete_intent': [ScenarioNeed.interaction],
        'f7_ongoing': [ScenarioNeed.interaction],
        'f8_full_screen_intent': [
          ScenarioNeed.interaction,
          ScenarioNeed.externalApproval,
        ],
        'f9_trampoline': [ScenarioNeed.interaction],
      };

      for (final scenario in groupF) {
        expect(
          scenario.needs,
          contains(ScenarioNeed.interaction),
          reason: scenario.id,
        );
        expect(scenario.needs, expected[scenario.id], reason: scenario.id);
        expect(scenario.isSupported, isFalse, reason: scenario.id);
      }
    });

    test('f5 alone is about the killed app, and is arranged to be sendable', () {
      // The gallery-wide invariant demands delayedSend and a positive delay for
      // any killed-app entry; asserted here too so this group's own file says
      // which of its nine may carry the flag. Pinning the other eight to false
      // is the half that catches the flag spreading to entries observable in
      // every app state, where it would tell the Sandbox nothing.
      final killed = scenarioF('f5_deeplink_killed');

      expect(killed.requiresKilledApp, isTrue);
      expect(killed.needs, contains(ScenarioNeed.delayedSend));
      expect(killed.defaultDelaySeconds, greaterThan(0));

      for (final scenario in groupF.where((s) => s.id != killed.id)) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(
          scenario.needs,
          isNot(contains(ScenarioNeed.delayedSend)),
          reason: scenario.id,
        );
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
      }
    });

    test('f8 also needs a permission Android 14+ may refuse', () {
      // contains('USE_FULL_SCREEN_INTENT') alone is satisfied by prose that
      // denies the requirement ("no USE_FULL_SCREEN_INTENT is needed") or that
      // promises the takeover works here, so the directional phrases are pinned
      // as well: who grants it, and what this app actually gets instead.
      final fullScreen = scenarioF('f8_full_screen_intent');

      expect(fullScreen.needs, contains(ScenarioNeed.externalApproval));
      expect(fullScreen.expectation, contains('USE_FULL_SCREEN_INTENT'));
      expect(fullScreen.expectation, contains('Android 14+ grants'));
      expect(fullScreen.expectation, contains('degraded heads-up'));

      // The channel this pretends to be a call on. No such channel exists yet —
      // that is what the interaction and channels work is for — but the template
      // has to name it, or there is nothing for the call-style notification to
      // be posted to.
      expect(androidNotificationOf(fullScreen)['channel_id'], 'calls');
    });

    test('the three deep-link scenarios carry three distinct routes', () {
      // isNotNull is far too weak: '' , 'true' and a bare number all pass it,
      // and none of them routes anywhere. Each link is therefore checked as a
      // non-blank absolute path — the shape the app's router accepts — and the
      // three are required to differ, because identical links would make the
      // foreground, background and killed paths indistinguishable on the device,
      // which is the entire reason these are three scenarios and not one.
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
      // Naming the API is not the same claim as "this is the commonest source
      // of bugs", and the API name alone would pass on a description that made
      // no such point. Both halves are pinned, so the entry cannot be reworded
      // into a bare mechanism note.
      final killed = scenarioF('f5_deeplink_killed');

      expect(killed.description, contains('getInitialMessage'));
      expect(
        killed.description,
        contains('commonest source of deep-link bugs'),
      );
    });

    test('every client-side feature is carried in data, as strings', () {
      // FCM has no field for actions, replies, delete intents or full-screen
      // intents, so all nine hand them to the client through `data` — and FCM's
      // data map is map<string, string>, so a bare `true` or `128` is a parse
      // failure rather than a value. Non-emptiness is the half that catches an
      // entry which declares an interaction need but gives the client nothing
      // to act on.
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
      // A scenario expected to fail has to say so, or it reads as a broken
      // entry. contains('fail') alone is satisfied by 'should not fail', so the
      // version that banned it and the statement that the error is the result
      // are both pinned.
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
