import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The one scenario in group J carrying [id].
Scenario scenarioJ(String id) => groupJ.firstWhere((s) => s.id == id);

/// Every path inside [node] whose key names an FCM delivery target.
///
/// Walks maps and lists to any depth, because the gallery-wide check only tests
/// `containsKey` on the template's top level. [path] prefixes what is reported,
/// so a hit names where it is rather than only that there is one.
Iterable<String> targetKeysIn(Object? node, String path) {
  const targetKeys = ['token', 'topic', 'condition'];
  final found = <String>[];

  if (node is Map) {
    for (final entry in node.entries) {
      final here = '$path/${entry.key}';
      if (targetKeys.contains(entry.key)) {
        found.add(here);
      }
      found.addAll(targetKeysIn(entry.value, here));
    }
  } else if (node is List) {
    for (final (index, item) in node.indexed) {
      found.addAll(targetKeysIn(item, '$path[$index]'));
    }
  }

  return found;
}

void main() {
  group('group J', () {
    test('offers all three targeting scenarios, in order', () {
      expect(groupJ.map((s) => s.id), [
        'j1_topic',
        'j2_condition',
        'j3_multicast',
      ]);
    });

    test('none of the targeting scenarios works yet', () {
      // hasLength(3) is what backs the word "none": without it a fourth entry
      // could be appended and this loop would still only be about the three
      // that happen to be here. `needs` is pinned exactly rather than merely
      // non-empty, so "which scenarios does the targeting work unblock?" stays
      // a truthful filter.
      expect(groupJ, hasLength(3));

      for (final scenario in groupJ) {
        expect(scenario.needs, [ScenarioNeed.targeting], reason: scenario.id);
        expect(scenario.isSupported, isFalse, reason: scenario.id);
      }
    });

    test('each declares its audience through target, not the payload', () {
      // The equality does discriminate the variant — every SendTarget's
      // operator== type-tests `other` first, so a ConditionTarget never equals
      // a TopicTarget of the same string. What equality alone does NOT pin is
      // the key that reaches the wire, and that key is the audience:
      // AllDevicesTarget in particular has no field at all, so its whole value
      // is its type and `expect(target, AllDevicesTarget())` says nothing about
      // what gets sent. toJson() is asserted beside each one for that reason.
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
      // These three are the only scenarios that put anything in the envelope,
      // so they are the only data that can break SendTarget.readFrom. A target
      // that does not round-trip would be a 400 from our own API at send time,
      // discovered on a device rather than here.
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
        // The distinction is why all three are blocked and it is not the same
        // reason. topic and condition are FCM's own oneof keys, so j1 and j2 are
        // sent and answered 200 today — and nothing arrives, because this device
        // has never subscribed. all_devices is ours, not FCM's, so j3 cannot be
        // sent at all and the API refuses it outright.
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
      // The gallery-wide check tests containsKey on the top level only, and
      // this is the group with an audience to smuggle. A nested
      // `data: {'topic': 'news'}` or a key under the free-form `apns.payload`
      // would pass that check untouched — FcmMessage cannot object either,
      // because both blocks are opaque to it — while reading to anyone scanning
      // the JSON as the scenario's audience. The audience lives in
      // Scenario.target and nowhere else.
      for (final scenario in groupJ) {
        expect(
          targetKeysIn(scenario.payloadTemplate, scenario.id),
          isEmpty,
          reason: scenario.id,
        );
      }
    });

    test('the recursive scan would really catch a nested target', () {
      // Guards the guard: an isEmpty assertion passes exactly as happily
      // against a scanner that never finds anything at all, which is the one
      // way the test above could be green while the data was wrong.
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
      // Targeting is about who receives a push, not what state they are in, so
      // the flag would be false on all three. It means "meaningless unless the
      // app is killed" and drags in delayed sending, so it is pinned off across
      // the group rather than left to the gallery-wide invariant, which only
      // checks the entries that set it.
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
