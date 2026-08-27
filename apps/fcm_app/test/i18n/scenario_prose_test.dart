import 'dart:io';

import 'package:fcm_app/i18n/scenario_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one scenario in [group] carrying [id].
///
/// One helper for every group file this suite draws from, rather than one per
/// group as the shared package's own tests each had: those files needed their own
/// copy because each compiled on its own, but this file already imports every
/// group's list.
Scenario _scenarioIn(List<Scenario> group, String id) =>
    group.firstWhere((s) => s.id == id);

void main() {
  late Translations en;

  setUpAll(() => en = AppLocale.en.buildSync());

  group('the whole gallery', () {
    // Task 1's coverage test already rejects an empty cs cell. This catches the
    // subtler miss: a row filled in by copying the English across.
    //
    // Grown from the actual failures the assertion below produced with an empty
    // list, not guessed: each of these three titles names a literal FCM or
    // Android API value, which is not prose to translate.
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

    // Moved from scenario_gallery_test.dart: the field this proved non-blank is
    // gone now, so this reads the CSV through the translations instead — and in
    // doing so also stands in for the oracle's "every scenario resolves a title
    // and a description", which had nothing left to move once this existed.
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

    // Moved from the deleted oracle: not a comparison against Dart prose — that
    // is gone — but a check that every value the enum can take resolves to
    // something, so a member added without a CSV row fails loudly rather than
    // rendering blank.
    test('every ScenarioNeed resolves a non-blank label', () {
      for (final need in ScenarioNeed.values) {
        expect(en.scenarioNeedLabel(need), isNotEmpty, reason: need.name);
      }
    });

    // Closes the guard above from the other direction. That one catches an enum
    // value with no CSV row; this one catches the opposite — a CSV row with no
    // enum value, which nothing else calls and so nothing else fails on. This is
    // exactly how `scenario_need.channels` outlived the `channels` enum value it
    // labelled once every scenario stopped naming it. Reads the CSV directly,
    // the same way csv_coverage_test.dart does, rather than through the
    // generated flat map, which is a private extension on `Translations` and not
    // reachable from here.
    test('every scenario_need CSV row still names a live ScenarioNeed', () {
      final lines = File('lib/i18n/strings.i18n.csv').readAsLinesSync();
      // Underscores included on purpose: the CSV spells these keys both ways —
      // `manualStep` beside `native_code` — because slang's `key_case: snake`
      // normalises either to the same generated key, so both spellings work and
      // both have been used. A pattern that stopped at the underscore would skip
      // the snake_case rows silently, which is the failure this test exists to
      // catch rather than commit.
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

    // These came from Dart literals until the previous task and now come from CSV
    // cells, where a leading or trailing space survives quoting unnoticed. Nothing
    // else in the suite would catch one: a padded string still resolves, still
    // renders, and still passes every `contains` assertion. Restores and widens a
    // guard the shared package's own test used to carry for `ScenarioNeed.label`.
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

    // Moved from scenario_gallery_test.dart.
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
    // Moved from group_b_test.dart.
    test('b5 expects NOT to arrive, and says so', () {
      // A scenario whose success is a non-delivery has to say so.
      // `contains('not')` would not do: the word "nothing" satisfies it
      // accidentally.
      final forceStopped = _scenarioIn(groupB, 'b5_force_stopped');
      final expectation = en.scenarioExpectation(forceStopped.l10nKey);

      expect(expectation, contains('nothing'));
      expect(expectation, contains('force-stopped'));
    });

    // Moved from group_b_test.dart.
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
    // Moved from group_c_test.dart: these are commands a user copies verbatim,
    // so the whole invocation is pinned.
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
    // Moved from group_d_test.dart.
    test('d5 names the custom sound on the channel it introduces', () {
      final sound = _scenarioIn(groupD, 'd5_custom_sound');
      expect(en.scenarioExpectation(sound.l10nKey), contains('res/raw'));
    });

    // Moved from group_d_test.dart.
    test('d7 states that Android ignores the change, and names the fix', () {
      // NOT "the immutability scenario is versioned": its own channel is chat_v1.
      // And contains('ignore') would be satisfied by "do not ignore", so both
      // halves are pinned to the phrase that carries the meaning.
      final immutable = _scenarioIn(groupD, 'd7_channel_immutability');

      expect(
        en.scenarioDescription(immutable.l10nKey),
        contains('ignore the change'),
      );
      expect(en.scenarioExpectation(immutable.l10nKey), contains('chat_v2'));
    });
  });

  group('group E', () {
    // Moved from group_e_test.dart. contains('Notification Service Extension')
    // alone would pass on prose that denied the requirement, so both halves of
    // the phrase are pinned.
    test('e2 says Android renders the image and iOS needs an extension', () {
      final remote = _scenarioIn(groupE, 'e2_image_remote');
      final expectation = en.scenarioExpectation(remote.l10nKey);

      expect(expectation, contains('Android does this natively'));
      expect(
        expectation,
        contains('iOS requires a Notification Service Extension'),
      );
    });

    // Moved from group_e_test.dart.
    test('e10 names the icon requirement that avoids the white-square bug', () {
      final colorAndIcon = _scenarioIn(groupE, 'e10_color_and_icon');
      expect(
        en.scenarioExpectation(colorAndIcon.l10nKey),
        contains('monochrome'),
      );
    });
  });

  group('group F', () {
    // Moved from group_f_test.dart. Both directional phrases are pinned: who
    // grants it, and what this app gets instead.
    test('f8 also needs a permission Android 14+ may refuse', () {
      final fullScreen = _scenarioIn(groupF, 'f8_full_screen_intent');
      final expectation = en.scenarioExpectation(fullScreen.l10nKey);

      expect(expectation, contains('USE_FULL_SCREEN_INTENT'));
      expect(expectation, contains('Android 14 and later grant'));
      expect(expectation, contains('degraded heads-up'));
    });

    // Moved from group_f_test.dart. The API name alone would pass on a
    // description that made no point about where the bugs are, so both halves
    // are pinned.
    test('f5 names getInitialMessage and says it is where the bugs are', () {
      final killed = _scenarioIn(groupF, 'f5_deeplink_killed');
      final description = en.scenarioDescription(killed.l10nKey);

      expect(description, contains('getInitialMessage'));
      expect(description, contains('commonest source of deep-link bugs'));
    });

    // Moved from group_f_test.dart. contains('platform code') alone is
    // satisfied by prose that never says the absence is on purpose, so the
    // deliberateness is pinned too — otherwise this reads as a gap rather
    // than a choice.
    test('f9 says it is not built, and that the omission is deliberate', () {
      final trampoline = _scenarioIn(groupF, 'f9_trampoline');
      final expectation = en.scenarioExpectation(trampoline.l10nKey);

      expect(expectation, contains('Not built'));
      expect(expectation, contains('platform code'));
      expect(expectation, contains('a choice, not an oversight'));
    });
  });

  group('group G', () {
    // Moved from group_g_test.dart. Sending once demonstrates nothing, so the
    // instruction is part of the entry.
    test('g2 replaces in place by reusing one tag of its own', () {
      final update = _scenarioIn(groupG, 'g2_update_same_id');
      expect(
        en.scenarioDescription(update.l10nKey),
        contains('Send twice with the same tag'),
      );
    });
  });

  group('group H', () {
    // Moved from group_h_test.dart. The expectation is checked to attribute the
    // block to Apple and to say the entry is listed rather than scheduled — the
    // one thing that distinguishes externalApproval.
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
    // Moved from group_i_test.dart. `contains('20')` proves neither the count
    // nor the rate, and the rate is the whole scenario — twenty pushes over an
    // afternoon is not a burst.
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
    // Moved from group_j_test.dart. j2 originally had no expectation, so a user
    // looking at it alone saw a blocked scenario with no stated cause.
    test('every blocked scenario states why, not just that it is blocked', () {
      for (final scenario in groupJ) {
        final expectation = en.scenarioExpectation(scenario.l10nKey);
        expect(expectation, isNotNull, reason: scenario.id);
        expect(expectation!.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    // Moved from group_j_test.dart.
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

    // Moved from group_j_test.dart: targeting is about who receives a push, not
    // a step performed by hand.
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
    // Moved from group_k_test.dart.
    test('the dead-token scenario reports UNREGISTERED', () {
      final dead = _scenarioIn(groupK, 'k2_invalid_token');
      expect(en.scenarioExpectation(dead.l10nKey), contains('UNREGISTERED'));
    });

    // Moved from group_k_test.dart. An entry that did not name its expected
    // error would leave the user unable to tell a working scenario from a
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

    // Moved from group_k_test.dart.
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

    // Moved from group_k_test.dart: a command the user copies verbatim.
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

    // Moved from group_k_test.dart: k3 is the app lacking the grant, k4 is the
    // user switching the app's notifications off while the grant stands — each
    // says which.
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
