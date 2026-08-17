import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'target_keys.dart';

/// The one scenario in group J carrying [id].
Scenario scenarioJ(String id) => groupJ.firstWhere((s) => s.id == id);

void main() {
  group('group J', () {
    test('every blocked scenario states why, not just that it is blocked', () {
      // j2 originally had no expectation, so a user looking at it alone saw a
      // blocked scenario with no stated cause.
      for (final scenario in groupJ) {
        expect(scenario.expectation, isNotNull, reason: scenario.id);
        expect(scenario.expectation!.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test('offers all three targeting scenarios, in order', () {
      expect(groupJ.map((s) => s.id), [
        'j1_topic',
        'j2_condition',
        'j3_multicast',
      ]);
    });

    test('none of the targeting scenarios works yet', () {
      // hasLength(3) backs the word "none", and `needs` is pinned exactly rather than
      // merely non-empty so the need stays a truthful filter.
      expect(groupJ, hasLength(3));

      for (final scenario in groupJ) {
        expect(scenario.needs, [ScenarioNeed.targeting], reason: scenario.id);
        expect(scenario.isSupported, isFalse, reason: scenario.id);
      }
    });

    test('each declares its audience through target, not the payload', () {
      // Equality discriminates the variant but not the key that reaches the wire, and
      // that key is the audience. AllDevicesTarget has no field at all, so its whole
      // value is its type — hence toJson() asserted beside each one.
      final topic = scenarioJ('j1_topic').target;
      expect(topic, const TopicTarget('news'));
      expect(topic?.toJson(), {'topic': 'news'});

      final condition = scenarioJ('j2_condition').target;
      expect(
        condition,
        const ConditionTarget("'news' in topics && 'beta' in topics"),
      );
      expect(condition?.toJson(), {
        'condition': "'news' in topics && 'beta' in topics",
      });

      final everyone = scenarioJ('j3_multicast').target;
      expect(everyone, const AllDevicesTarget());
      expect(everyone?.toJson(), {'all_devices': true});
    });

    test('every target survives the envelope reader it will be sent through', () {
      // The only scenarios that put anything in the envelope, so the only data that
      // can break SendTarget.readFrom — otherwise a 400 discovered on a device.
      for (final scenario in groupJ) {
        final target = scenario.target;
        expect(target, isNotNull, reason: scenario.id);
        expect(
          SendTarget.readFrom(target!.toJson()),
          target,
          reason: scenario.id,
        );
      }
    });

    test(
      'two of the three are blocked on subscribing, the third on a registry',
      () {
        // All three are blocked, for two reasons: topic and condition are FCM's own
        // oneof keys, so j1 and j2 are answered 200 while nothing arrives, whereas
        // all_devices is ours and the API refuses it outright.
        expect(
          groupJ
              .where((s) => s.target?.toJson().keys.single != 'all_devices')
              .map((s) => s.id),
          ['j1_topic', 'j2_condition'],
        );

        final topic = scenarioJ('j1_topic').expectation;
        expect(topic, contains('200'));
        expect(topic, contains('subscribe'));

        final multicast = scenarioJ('j3_multicast').expectation;
        expect(multicast, contains('501'));
        expect(multicast, contains('token registry'));
      },
    );

    test('no template names an audience at any depth', () {
      // The gallery-wide check tests containsKey on the top level only, and this is
      // the group with an audience to smuggle: a nested `data: {'topic': 'news'}`
      // passes it untouched, and FcmMessage cannot object either.
      for (final scenario in groupJ) {
        expect(
          targetKeysIn(scenario.payloadTemplate, scenario.id),
          isEmpty,
          reason: scenario.id,
        );
      }
    });

    test('the recursive scan would really catch a nested target', () {
      // Guards the guard: an isEmpty assertion passes just as happily against a
      // scanner that never finds anything.
      const nestedInData = {
        'notification': {'title': 'Topic push'},
        'data': {'topic': 'news'},
      };
      const nestedInAList = {
        'apns': {
          'payload': [
            {'token': 'abc'},
          ],
        },
      };

      expect(targetKeysIn(nestedInData, 'x'), ['x/data/topic']);
      expect(targetKeysIn(nestedInAList, 'x'), ['x/apns/payload[0]/token']);
    });

    test('nothing in this group is about the killed app', () {
      // Targeting is about who receives a push, not what state they are in, so the
      // flag is false on all three.
      for (final scenario in groupJ) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
        expect(scenario.manualSteps, isNull, reason: scenario.id);
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupJ) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
