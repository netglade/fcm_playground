import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'target_keys.dart';

void main() {
  test('every id is unique', () {
    final ids = scenarioGallery.map((s) => s.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every l10nKey is unique', () {
    final l10nKeys = scenarioGallery.map((s) => s.l10nKey).toList();

    expect(
      l10nKeys.toSet(),
      hasLength(l10nKeys.length),
      reason:
          'a duplicated l10nKey renders one scenario\'s title, description, '
          'expectation and manual steps under two different ids, and every '
          'other test here stays green: id is still unique and both keys '
          'still resolve — the natural way to add a scenario is to duplicate '
          'one and change id, which is exactly how this slips in if l10nKey '
          'is forgotten',
    );
  });

  test("every id starts with its group's letter", () {
    // The one assertion that catches an entry filed under the wrong table as
    // eleven files grow independently.
    for (final scenario in scenarioGallery) {
      expect(
        scenario.id,
        startsWith(scenario.group.toLowerCase()),
        reason: '${scenario.id} is filed under ${scenario.group}',
      );
    }
  });

  test('every template round-trips through the typed model', () {
    // 66 hand-written templates is where a `titel` typo slips in. The strict parser
    // plus this assertion makes it a failed build rather than an opaque 400.
    for (final scenario in scenarioGallery) {
      final raw = Map<String, Object?>.from(scenario.payloadTemplate);
      expect(FcmMessage.fromJson(raw).toJson(), raw, reason: scenario.id);
    }
  });

  test('no template sets its own delivery target, at any depth', () {
    // Deep, not containsKey: the top level is already protected by FcmMessage.read,
    // but a nested `data: {'topic': 'news'}` slips past both it and a shallow check.
    for (final scenario in scenarioGallery) {
      expect(
        targetKeysIn(scenario.payloadTemplate, scenario.id),
        isEmpty,
        reason: '${scenario.id} sets a target; use Scenario.target instead',
      );
    }
  });

  test('the deep scan would really catch a nested target', () {
    // The assertion above is isEmpty, which a scanner that never finds anything
    // satisfies too. Two positive fixtures keep it honest.
    const inData = {
      'data': {'topic': 'news'},
    };
    const inFreeForm = {
      'apns': {
        'payload': [
          {'token': 'abc'},
        ],
      },
    };

    expect(targetKeysIn(inData, 'x'), ['x/data/topic']);
    expect(targetKeysIn(inFreeForm, 'x'), ['x/apns/payload[0]/token']);
  });

  // Whether every scenario resolves a non-blank title and description moved to
  // apps/fcm_app/test/i18n/scenario_prose_test.dart: this package has no access
  // to the translations that prose now lives in.

  test('a killed-app scenario says how long to hold the send', () {
    // Gives requiresKilledApp exactly one meaning: "meaningless unless the app is
    // killed". Arranging that means holding the send, so the flag still guarantees
    // a positive delay — but it no longer implies anything about needs, since
    // delayed sending is arranged for every scenario without asking.
    for (final scenario in scenarioGallery) {
      if (scenario.requiresKilledApp) {
        expect(
          scenario.defaultDelaySeconds,
          greaterThan(0),
          reason: '${scenario.id} must say how long to hold the send',
        );
      }
    }
  });

  // Whether a manual-step scenario says what the step is moved to
  // apps/fcm_app/test/i18n/scenario_prose_test.dart.

  test('the catalogue is complete: 66 scenarios in 11 groups', () {
    expect(scenarioGallery, hasLength(66));
    expect(scenarioGallery.map((s) => s.group).toSet(), hasLength(11));
  });

  test('exactly 32 scenarios work today', () {
    // Asserted so that mis-marking one as blocked, or quietly unmarking one to
    // make it look supported, fails the build.
    final supported = scenarioGallery.where((s) => s.isSupported).toList();

    expect(
      supported,
      hasLength(32),
      reason: supported.map((s) => s.id).join(', '),
    );
  });

  test('every ScenarioNeed is used, so the enum cannot drift', () {
    final usedBy = {
      for (final need in ScenarioNeed.values)
        need: scenarioGallery
            .where((s) => s.needs.contains(need))
            .map((s) => s.id)
            .toList(),
    };

    for (final need in ScenarioNeed.values) {
      expect(
        usedBy[need],
        isNotEmpty,
        reason: '${need.name} is declared but no scenario needs it',
      );
    }

    // A need carried by a single scenario is one whose whole justification is that
    // entry, so the loop above stays green if it is renamed or swapped. The sole
    // users are pinned by id, and so is *which* needs are sole-use.
    final soleUse = {
      for (final entry in usedBy.entries)
        if (entry.value.length == 1) entry.key.name: entry.value.single,
    };

    expect(soleUse, {'badge': 'g3_badge', 'nativeCode': 'f9_trampoline'});
  });

  test('the groups appear in A to K order, each in one run', () {
    final letters = scenarioGallery.map((s) => s.group).toList();

    // `toSet()` keeps insertion order, but deduplication is not harmless: A, B, A
    // collapses to [A, B] and would pass while group A was split in two. So the
    // distinct letters are compared *and* the raw sequence must never go backwards.
    expect(letters.toSet().toList(), const [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
    ]);
    expect(letters, [...letters]..sort());
  });

  group('group A', () {
    test('offers all four basic-delivery scenarios', () {
      expect(groupA.map((s) => s.id), [
        'a1_notification_only',
        'a2_data_only',
        'a3_hybrid',
        'a4_no_display',
      ]);
    });

    test('all four work today, with nothing outstanding', () {
      for (final scenario in groupA) {
        expect(scenario.isSupported, isTrue, reason: scenario.id);
      }
    });

    test('the data-only scenario carries no notification block', () {
      final dataOnly = groupA.firstWhere((s) => s.id == 'a2_data_only');

      expect(dataOnly.payloadTemplate.containsKey('notification'), isFalse);
      expect(dataOnly.payloadTemplate['data'], isNotEmpty);
      // Sendable today, so no killed-app flag: see the comment on the entry.
      expect(dataOnly.requiresKilledApp, isFalse);
      expect(dataOnly.isSupported, isTrue);
    });

    test('the hybrid scenario carries both blocks', () {
      final hybrid = groupA.firstWhere((s) => s.id == 'a3_hybrid');

      expect(hybrid.payloadTemplate['notification'], isNotNull);
      expect(hybrid.payloadTemplate['data'], isNotNull);
    });
  });
}
