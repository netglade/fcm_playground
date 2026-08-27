import 'dart:io';

import 'package:fcm_app/i18n/scenario_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one scenario in [group] carrying [id].
///
/// One helper for every group, unlike the shared package's per-file copies — this
/// file already imports every group's list.
Scenario _scenarioIn(List<Scenario> group, String id) =>
    group.firstWhere((s) => s.id == id);

void main() {
  late Translations en;

  setUpAll(() => en = AppLocale.en.buildSync());

  group('the whole gallery', () {
    // csv_coverage_test already rejects an empty cs cell; this catches the
    // subtler miss, a row filled in by copying the English across. These three
    // are exempt because each title names a literal API value, not prose.
    const sameInBothLanguages = <String>{
      // 'android.priority HIGH', the field's own value.
      'c1_priority_high',
      // 'android.priority NORMAL', the field's own value.
      'c2_priority_normal',
      // 'CATEGORY_ALARM', the Android constant it demonstrates.
      'h2_category_alarm',
    };

    test('every scenario reads differently in Czech', () {
      final cs = AppLocale.cs.buildSync();

      for (final scenario in scenarioGallery) {
        if (sameInBothLanguages.contains(scenario.l10nKey)) continue;

        expect(
          cs.scenarioTitle(scenario.l10nKey),
          isNot(en.scenarioTitle(scenario.l10nKey)),
          reason: '${scenario.id} reads identically in both languages',
        );
      }
    });

    // Reads the CSV through the translations, the field it used to check being
    // gone.
    test('every scenario resolves a non-blank title and description', () {
      for (final scenario in scenarioGallery) {
        expect(
          en.scenarioTitle(scenario.l10nKey).trim(),
          isNotEmpty,
          reason: scenario.id,
        );
        expect(
          en.scenarioDescription(scenario.l10nKey).trim(),
          isNotEmpty,
          reason: scenario.id,
        );
      }
    });

    // Every enum value must resolve to something, so a member added without a
    // CSV row fails loudly rather than rendering blank.
    test('every ScenarioNeed resolves a non-blank label', () {
      for (final need in ScenarioNeed.values) {
        expect(en.scenarioNeedLabel(need), isNotEmpty, reason: need.name);
      }
    });

    // The other direction: a CSV row with no enum value, which nothing calls and
    // so nothing else fails on. That is how `scenario_need.channels` outlived the
    // enum value it labelled. Reads the CSV directly — the generated flat map is
    // a private extension and unreachable here.
    test('every scenario_need CSV row still names a live ScenarioNeed', () {
      final lines = File('lib/i18n/strings.i18n.csv').readAsLinesSync();
      // Underscores included: the CSV spells these both ways, since
      // `key_case: snake` normalises either to one generated key. A pattern
      // stopping at the underscore would silently skip the snake_case rows.
      final needPattern = RegExp(r'^scenario_need\.([A-Za-z0-9_]+),');
      final rowNames = <String>{};
      for (final line in lines) {
        final match = needPattern.firstMatch(line);
        if (match != null) rowNames.add(match.group(1)!);
      }

      // Compared against both spellings for the same reason.
      final enumNames = {
        for (final need in ScenarioNeed.values) ...{
          need.name,
          need.name.replaceAllMapped(
            RegExp('[A-Z]'),
            (m) => '_${m.group(0)!.toLowerCase()}',
          ),
        },
      };

      expect(
        rowNames.difference(enumNames),
        isEmpty,
        reason:
            'a scenario_need.* row names no live ScenarioNeed — delete the '
            'row and regenerate',
      );
    });

    // A leading or trailing space survives CSV quoting unnoticed, and nothing
    // else would catch it: a padded string still resolves, still renders, and
    // still passes every `contains` assertion.
    test('no translated string carries stray outer whitespace', () {
      final cs = AppLocale.cs.buildSync();

      for (final translations in [en, cs]) {
        for (final scenario in scenarioGallery) {
          final values = <String>[
            translations.scenarioTitle(scenario.l10nKey),
            translations.scenarioDescription(scenario.l10nKey),
            ?translations.scenarioExpectation(scenario.l10nKey),
            ?translations.scenarioManualSteps(scenario.l10nKey),
          ];
          for (final value in values) {
            expect(value.trim(), value, reason: scenario.id);
          }
        }

        for (final need in ScenarioNeed.values) {
          final label = translations.scenarioNeedLabel(need);
          expect(label.trim(), label, reason: need.name);
        }
      }
    });

    test('a manual-step scenario says what the step is', () {
      for (final scenario in scenarioGallery) {
        if (scenario.needs.contains(ScenarioNeed.manualStep)) {
          expect(
            en.scenarioManualSteps(scenario.l10nKey),
            isNotNull,
            reason: scenario.id,
          );
        }
      }
    });
  });

  group('group B', () {
    test('b5 expects NOT to arrive, and says so', () {
      // A scenario whose success is a non-delivery must say so.
      // `contains('not')` would not do — "nothing" satisfies it by accident.
      final forceStopped = _scenarioIn(groupB, 'b5_force_stopped');
      final expectation = en.scenarioExpectation(forceStopped.l10nKey);

      expect(expectation, contains('nothing'));
      expect(expectation, contains('force-stopped'));
    });

    test('every manual-step scenario spells out the step', () {
      for (final scenario in groupB) {
        if (scenario.needs.contains(ScenarioNeed.manualStep)) {
          final steps = en.scenarioManualSteps(scenario.l10nKey);
          expect(steps, isNotNull, reason: scenario.id);
          expect(steps!.trim(), isNotEmpty, reason: scenario.id);
        }
      }
    });
  });

  group('group C', () {
    // Commands a user copies verbatim, so the whole invocation is pinned.
    test('the adb scenarios carry a runnable command, not just a keyword', () {
      expect(
        en.scenarioManualSteps(_scenarioIn(groupC, 'c6_doze_test').l10nKey),
        contains('adb shell dumpsys deviceidle force-idle'),
      );
      expect(
        en.scenarioManualSteps(
          _scenarioIn(groupC, 'c7_standby_bucket').l10nKey,
        ),
        contains('adb shell am set-standby-bucket cz.netglade.fcm_app'),
      );
    });
  });

  group('group D', () {
    test('d5 names the custom sound on the channel it introduces', () {
      final sound = _scenarioIn(groupD, 'd5_custom_sound');
      expect(en.scenarioExpectation(sound.l10nKey), contains('res/raw'));
    });

    test('d7 states that Android ignores the change, and names the fix', () {
      // Not "versioned" — its own channel is chat_v1. And contains('ignore')
      // would accept "do not ignore", so both halves are pinned.
      final immutable = _scenarioIn(groupD, 'd7_channel_immutability');

      expect(
        en.scenarioDescription(immutable.l10nKey),
        contains('ignore the change'),
      );
      expect(en.scenarioExpectation(immutable.l10nKey), contains('chat_v2'));
    });
  });

  group('group E', () {
    // The API name alone would pass on prose denying the requirement, so both
    // halves are pinned.
    test('e2 says Android renders the image and iOS needs an extension', () {
      final remote = _scenarioIn(groupE, 'e2_image_remote');
      final expectation = en.scenarioExpectation(remote.l10nKey);

      expect(expectation, contains('Android does this natively'));
      expect(
        expectation,
        contains('iOS requires a Notification Service Extension'),
      );
    });

    test('e10 names the icon requirement that avoids the white-square bug', () {
      final colorAndIcon = _scenarioIn(groupE, 'e10_color_and_icon');
      expect(
        en.scenarioExpectation(colorAndIcon.l10nKey),
        contains('monochrome'),
      );
    });
  });

  group('group F', () {
    // Both directions pinned: who grants it, and what this app gets instead.
    test('f8 also needs a permission Android 14+ may refuse', () {
      final fullScreen = _scenarioIn(groupF, 'f8_full_screen_intent');
      final expectation = en.scenarioExpectation(fullScreen.l10nKey);

      expect(expectation, contains('USE_FULL_SCREEN_INTENT'));
      expect(expectation, contains('Android 14 and later grant'));
      expect(expectation, contains('degraded heads-up'));
    });

    // The API name alone would pass on prose making no point about where the
    // bugs are, so both halves are pinned.
    test('f5 names getInitialMessage and says it is where the bugs are', () {
      final killed = _scenarioIn(groupF, 'f5_deeplink_killed');
      final description = en.scenarioDescription(killed.l10nKey);

      expect(description, contains('getInitialMessage'));
      expect(description, contains('commonest source of deep-link bugs'));
    });

    // contains('platform code') alone never says the absence is deliberate, so
    // that is pinned too — otherwise it reads as a gap rather than a choice.
    test('f9 says it is not built, and that the omission is deliberate', () {
      final trampoline = _scenarioIn(groupF, 'f9_trampoline');
      final expectation = en.scenarioExpectation(trampoline.l10nKey);

      expect(expectation, contains('Not built'));
      expect(expectation, contains('platform code'));
      expect(expectation, contains('a choice, not an oversight'));
    });
  });

  group('group G', () {
    // Sending once demonstrates nothing, so the instruction is part of the
    // entry.
    test('g2 replaces in place by reusing one tag of its own', () {
      final update = _scenarioIn(groupG, 'g2_update_same_id');
      expect(
        en.scenarioDescription(update.l10nKey),
        contains('Send twice with the same tag'),
      );
    });
  });

  group('group H', () {
    // Must attribute the block to Apple and say the entry is listed rather than
    // scheduled — what distinguishes externalApproval.
    test('h4 is permanently blocked on Apple, not on us', () {
      final critical = _scenarioIn(groupH, 'h4_ios_critical');
      final expectation = en.scenarioExpectation(critical.l10nKey);

      expect(expectation, isNotNull);
      expect(expectation, contains('critical-alert entitlement'));
      expect(expectation, contains('Apple must approve'));
      expect(expectation, contains('rather than scheduled'));
    });
  });

  group('group I', () {
    // `contains('20')` proves neither count nor rate, and the rate is the whole
    // scenario — twenty pushes over an afternoon is not a burst.
    test('the burst scenario says how many and how fast', () {
      final burst = _scenarioIn(groupI, 'i4_burst');
      final steps = en.scenarioManualSteps(burst.l10nKey);

      expect(steps, isNotNull);
      expect(steps!.trim(), isNotEmpty);
      expect(steps, contains('20 times'));
      expect(steps, contains('within 10 seconds'));
    });
  });

  group('group J', () {
    // j2 once had none, leaving a blocked scenario with no stated cause.
    test('every blocked scenario states why, not just that it is blocked', () {
      for (final scenario in groupJ) {
        final expectation = en.scenarioExpectation(scenario.l10nKey);
        expect(expectation, isNotNull, reason: scenario.id);
        expect(expectation!.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test(
      'two of the three are blocked on subscribing, the third on a registry',
      () {
        final topic = en.scenarioExpectation(
          _scenarioIn(groupJ, 'j1_topic').l10nKey,
        );
        expect(topic, contains('200'));
        expect(topic, contains('subscribe'));

        final multicast = en.scenarioExpectation(
          _scenarioIn(groupJ, 'j3_multicast').l10nKey,
        );
        expect(multicast, contains('501'));
        expect(multicast, contains('token registry'));
      },
    );

    // Targeting is about who receives a push, not a step done by hand.
    test('no group-J scenario carries a manual step', () {
      for (final scenario in groupJ) {
        expect(
          en.scenarioManualSteps(scenario.l10nKey),
          isNull,
          reason: scenario.id,
        );
      }
    });
  });

  group('group K', () {
    test('the dead-token scenario reports UNREGISTERED', () {
      final dead = _scenarioIn(groupK, 'k2_invalid_token');
      expect(en.scenarioExpectation(dead.l10nKey), contains('UNREGISTERED'));
    });

    // Without its expected error, a user cannot tell a working scenario from a
    // broken one.
    test('both supported failures say which error they should produce', () {
      expect(
        en.scenarioExpectation(
          _scenarioIn(groupK, 'k1_payload_oversize').l10nKey,
        ),
        contains('INVALID_ARGUMENT'),
      );
      expect(
        en.scenarioExpectation(_scenarioIn(groupK, 'k2_invalid_token').l10nKey),
        contains('UNREGISTERED'),
      );
    });

    test('the three device states need a manual step and spell it out', () {
      const deviceStates = [
        'k3_permission_denied',
        'k4_notifications_disabled',
        'k5_battery_restricted',
      ];

      for (final id in deviceStates) {
        final steps = en.scenarioManualSteps(_scenarioIn(groupK, id).l10nKey);
        expect(steps, isNotNull, reason: id);
        expect(steps!.trim(), isNotEmpty, reason: id);
      }
    });

    // A command the user copies verbatim.
    test('k3 carries the runnable revoke command, not just the word', () {
      expect(
        en.scenarioManualSteps(
          _scenarioIn(groupK, 'k3_permission_denied').l10nKey,
        ),
        contains(
          'adb shell pm revoke cz.netglade.fcm_app '
          'android.permission.POST_NOTIFICATIONS',
        ),
      );
    });

    // k3 is the app lacking the grant; k4 is the user switching notifications
    // off while the grant stands.
    test('k3 and k4 are different failures, and each says which', () {
      expect(
        en.scenarioManualSteps(
          _scenarioIn(groupK, 'k3_permission_denied').l10nKey,
        ),
        contains('revoke'),
      );
      expect(
        en.scenarioDescription(
          _scenarioIn(groupK, 'k4_notifications_disabled').l10nKey,
        ),
        contains('the app has the grant'),
      );
      expect(
        en.scenarioManualSteps(
          _scenarioIn(groupK, 'k4_notifications_disabled').l10nKey,
        ),
        contains('Settings'),
      );
    });
  });
}
