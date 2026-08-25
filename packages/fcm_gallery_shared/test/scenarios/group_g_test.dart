import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `android.notification` block of [scenario]'s template. Reaches through with
/// `!`, so a missing level fails the test rather than reading as null.
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

    test('three of the four work today, and the launcher badge says why', () {
      // `isSupported` is just `needs.isEmpty`, so it passes for any entries carrying
      // any non-empty needs — including ones filed under the wrong sub-project. Needs
      // are pinned exactly, and hasLength(4) backs the group having four entries in
      // total, of which only g3 is still blocked.
      expect(groupG, hasLength(4));

      const expected = {
        'g1_group_summary': <ScenarioNeed>[],
        'g2_update_same_id': <ScenarioNeed>[],
        'g3_badge': [ScenarioNeed.badge],
        'g4_badge_ios': <ScenarioNeed>[],
      };

      for (final scenario in groupG) {
        expect(scenario.needs, expected[scenario.id], reason: scenario.id);
      }

      expect(groupG.where((s) => s.isSupported).map((s) => s.id), [
        'g1_group_summary',
        'g2_update_same_id',
        'g4_badge_ios',
      ]);
    });

    test('the Android badge uses notification_count, an FCM typed int', () {
      // `expect(x, 5)` is satisfied by 5.0 too, and notification_count is a typed
      // int32, so a double there is a 400 from Google. Hence isA<int>().
      final badge = scenarioG('g3_badge');
      final count = androidNotificationOf(badge)['notification_count'];

      expect(count, isA<int>());
      expect(count, 5);
      expect(badge.needs, [ScenarioNeed.badge]);
    });

    test('the iOS badge rides inside the free-form aps dictionary', () {
      // The same 5.0-equals-5 hole, and worse: apns.payload is free-form, so the
      // round-trip preserves a double happily. This is the only guard.
      final badge = apsOf(scenarioG('g4_badge_ios'))['badge'];

      expect(badge, isA<int>());
      expect(badge, 7);
    });

    test('g4 keeps a realistically nested aps dictionary', () {
      // The app's dotted-path round-trip test sources its fixture from this entry and
      // only proves anything while the payload stays nested — APNs also accepts a
      // flat `'alert': 'text'`. The shape is pinned here, where the entry lives.
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

    test('g2 has a tag, g1 has none', () {
      // isNotNull is satisfied by '', 0 and false, none of which Android replaces a
      // notification by. g1 must carry no tag at all — the notification id now
      // derives from the tag, so a tag on g1 would collapse all five of its sends
      // into one notification replacing itself, breaking g1 itself rather than
      // merely colliding with g2.
      final update = scenarioG('g2_update_same_id');
      final tag = androidNotificationOf(update)['tag'];

      expect(tag, isA<String>());
      expect((tag! as String).trim(), isNotEmpty);
      expect(
        androidNotificationOf(scenarioG('g1_group_summary')).containsKey('tag'),
        isFalse,
      );

      // Sending once demonstrates nothing, so the instruction is part of the entry.
      expect(update.description, contains('Send twice with the same tag'));
    });

    test('nothing in this group is about the killed app', () {
      // All four are about what the system does with several notifications at once,
      // so they are observable in every app state. The flag would drag in delayed
      // sending, and the gallery-wide invariant only checks entries that set it.
      for (final scenario in groupG) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
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
