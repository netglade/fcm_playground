import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `android.notification` block of [scenario]'s template.
///
/// Reaches through with `!`, so an entry missing either level fails the test
/// rather than reading as null.
Map<Object?, Object?> androidNotificationOf(Scenario scenario) {
  final android = scenario.payloadTemplate['android']! as Map<Object?, Object?>;

  return android['notification']! as Map<Object?, Object?>;
}

/// The `apns.payload.aps` dictionary of [scenario]'s template.
Map<Object?, Object?> apsOf(Scenario scenario) {
  final apns = scenario.payloadTemplate['apns']! as Map<Object?, Object?>;
  final payload = apns['payload']! as Map<Object?, Object?>;

  return payload['aps']! as Map<Object?, Object?>;
}

/// The one scenario in group G carrying [id].
Scenario scenarioG(String id) => groupG.firstWhere((s) => s.id == id);

void main() {
  group('group G', () {
    test('offers all four group, badge and update scenarios, in order', () {
      expect(groupG.map((s) => s.id), [
        'g1_group_summary',
        'g2_update_same_id',
        'g3_badge',
        'g4_badge_ios',
      ]);
    });

    test('only the iOS badge scenario works today, and the rest say why', () {
      // `where(isSupported)` alone is far too weak to carry this name:
      // isSupported is just `needs.isEmpty`, so the assertion passes for any
      // three entries carrying any non-empty needs at all — including three
      // filed under the wrong sub-project, which would make "which scenarios
      // does the badge work unblock?" answer wrongly. Each entry's needs are
      // therefore pinned exactly, and hasLength(4) is what backs the word
      // "only": without it a fifth supported entry could be appended and the
      // list comparison below would still be about the four checked here.
      expect(groupG, hasLength(4));

      const expected = {
        'g1_group_summary': [ScenarioNeed.interaction],
        'g2_update_same_id': [ScenarioNeed.interaction],
        'g3_badge': [ScenarioNeed.badge],
        'g4_badge_ios': <ScenarioNeed>[],
      };

      for (final scenario in groupG) {
        expect(scenario.needs, expected[scenario.id], reason: scenario.id);
      }

      expect(groupG.where((s) => s.isSupported).map((s) => s.id), [
        'g4_badge_ios',
      ]);
    });

    test('the Android badge uses notification_count, an FCM typed int', () {
      // `expect(x, 5)` is satisfied by 5.0 as well — Dart's `5.0 == 5` is true —
      // and notification_count is a typed int32 on FCM's AndroidNotification, so
      // a double there is a 400 from Google that this file would have passed.
      // Hence isA<int>() beside the value.
      final badge = scenarioG('g3_badge');
      final count = androidNotificationOf(badge)['notification_count'];

      expect(count, isA<int>());
      expect(count, 5);
      expect(badge.needs, [ScenarioNeed.badge]);
    });

    test('the iOS badge rides inside the free-form aps dictionary', () {
      // The same 5.0-equals-5 hole, and worse here: apns.payload is free-form,
      // so the typed model forwards whatever it is given and the gallery-wide
      // round-trip would happily preserve a double. This is the only guard.
      final badge = apsOf(scenarioG('g4_badge_ios'))['badge'];

      expect(badge, isA<int>());
      expect(badge, 7);
    });

    test('g4 keeps a realistically nested aps dictionary', () {
      // apps/fcm_app/test/sandbox/forms/platform_config_forms_test.dart sources
      // its dotted-path round-trip from this entry, and that test only proves
      // anything while the payload stays nested: APNs also accepts a flat
      // `'alert': 'text'`, which would silently reduce that coverage to a
      // one-level map. The shape is pinned here, where the entry lives.
      final scenario = scenarioG('g4_badge_ios');
      final apns = scenario.payloadTemplate['apns']! as Map<Object?, Object?>;
      final headers = apns['headers']! as Map<Object?, Object?>;
      final alert = apsOf(scenario)['alert']! as Map<Object?, Object?>;

      expect(headers['apns-priority'], '10');
      expect(alert['title'], isA<String>());
      expect(alert['title']! as String, isNotEmpty);
      expect(alert['body'], isA<String>());
      expect(alert['body']! as String, isNotEmpty);
      expect(apsOf(scenario)['sound'], 'default');
    });

    test('g2 replaces in place by reusing one tag of its own', () {
      // isNotNull is what this was, and it is satisfied by '', 0 and false —
      // none of which Android will replace a notification by, since it matches
      // on the tag string. The tag is therefore checked as a non-blank String.
      //
      // It must also differ from g1's: g1 tags a group row, so a shared tag
      // would make g2's second send replace the summary instead of its own
      // first send, and the two scenarios would be indistinguishable on the
      // device — which is the whole reason they are two entries.
      final update = scenarioG('g2_update_same_id');
      final tag = androidNotificationOf(update)['tag'];

      expect(tag, isA<String>());
      expect((tag! as String).trim(), isNotEmpty);
      expect(
        tag,
        isNot(androidNotificationOf(scenarioG('g1_group_summary'))['tag']),
      );

      // Sending once demonstrates nothing at all here, so the instruction to
      // send twice is part of the entry rather than a nicety.
      expect(update.description, contains('Send twice with the same tag'));
    });

    test('nothing in this group is about the killed app', () {
      // Group G is observable in every app state: all four are about what the
      // system does with several notifications at once. The flag means
      // "meaningless unless the app is killed" and would drag in delayed
      // sending, so it is pinned off across the group rather than left to the
      // gallery-wide invariant, which only checks entries that set it.
      for (final scenario in groupG) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
        expect(
          scenario.needs,
          isNot(contains(ScenarioNeed.delayedSend)),
          reason: scenario.id,
        );
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupG) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
