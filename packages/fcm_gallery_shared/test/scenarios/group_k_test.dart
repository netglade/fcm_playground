import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'target_keys.dart';

/// The one scenario in group K carrying [id].
Scenario scenarioK(String id) => groupK.firstWhere((s) => s.id == id);

void main() {
  group('group K', () {
    test('offers all five edge cases, in order', () {
      expect(groupK.map((s) => s.id), [
        'k1_payload_oversize',
        'k2_invalid_token',
        'k3_permission_denied',
        'k4_notifications_disabled',
        'k5_battery_restricted',
      ]);
    });

    test('the two payload-level failures work today, and only those two', () {
      // hasLength(5) makes "only those two" true of the group rather than of
      // whichever entries happen to be present.
      expect(groupK, hasLength(5));
      expect(groupK.where((s) => s.isSupported).map((s) => s.id), [
        'k1_payload_oversize',
        'k2_invalid_token',
      ]);
    });

    test("the oversize payload really is over FCM's 4 KB limit", () {
      // Asserting the size rather than trusting the name: a template trimmed
      // during editing would silently stop testing the limit.
      final data =
          scenarioK('k1_payload_oversize').payloadTemplate['data']!
              as Map<String, Object?>;
      final characters = data.entries
          .map((e) => e.key.length + (e.value! as String).length)
          .reduce((a, b) => a + b);

      expect(characters, greaterThan(4096));

      // ...but that sum is not what FCM measures: String.length counts UTF-16 code
      // units while FCM counts bytes, so the two agree only while the text is ASCII.
      // The bytes of the JSON that goes on the wire are asserted beside it.
      final bytes = utf8.encode(jsonEncode(data)).length;

      expect(bytes, greaterThan(4096));
      expect(
        bytes,
        greaterThanOrEqualTo(characters),
        reason: 'serialising can only add to the size',
      );

      // The strictest reading of the limit, and why the chunks are as long as they
      // are: even the value bytes alone are over 4 KB. The first draft cleared 4096
      // only once keys and quoting were counted.
      final valueBytes = data.values
          .map((v) => utf8.encode(v! as String).length)
          .reduce((a, b) => a + b);

      expect(valueBytes, greaterThan(4096));
    });

    test('the dead-token scenario targets a token, and a plainly dead one', () {
      final dead = scenarioK('k2_invalid_token');
      final target = dead.target;

      expect(target, isA<TokenTarget>());
      expect((target! as TokenTarget).token, isNot(isEmpty));
      // The token has to stay obviously fake: pasting a real device token in turns a
      // guaranteed UNREGISTERED into a real delivery and stops testing the error
      // path.
      expect((target as TokenTarget).token, contains('never-real'));
      expect(target.toJson().keys.single, 'token');
      // What the expectation says about UNREGISTERED moved to
      // apps/fcm_app/test/i18n/scenario_prose_test.dart.
    });

    test('k2 is the catalogue\'s only supported scenario with an audience', () {
      // The group-J targets are all blocked, so k2 is the only entry that both
      // carries a target and can be sent today.
      expect(
        scenarioGallery
            .where((s) => s.isSupported && s.target != null)
            .map((s) => s.id),
        ['k2_invalid_token'],
      );
    });

    // Which error each supported failure says it should produce, and the wording
    // of the three device states' manual steps (including k3's runnable revoke
    // command and how k3 and k4's prose tells them apart), all moved to
    // apps/fcm_app/test/i18n/scenario_prose_test.dart.
    test('the three device states each need a manual step', () {
      const deviceStates = [
        'k3_permission_denied',
        'k4_notifications_disabled',
        'k5_battery_restricted',
      ];

      for (final id in deviceStates) {
        expect(scenarioK(id).needs, [ScenarioNeed.manualStep], reason: id);
      }
    });

    test('nothing in this group is about the killed app', () {
      // Errors and device states are observable in every app state, so the flag is
      // off across the group.
      for (final scenario in groupK) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
      }
    });

    test('no template names an audience at any depth', () {
      // k2 is the one supported scenario with a target, so this is where the audience
      // is most likely to leak: a nested `data: {'token': …}` passes FcmMessage and a
      // top-level containsKey check alike.
      for (final scenario in groupK) {
        expect(
          targetKeysIn(scenario.payloadTemplate, scenario.id),
          isEmpty,
          reason: scenario.id,
        );
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupK) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
