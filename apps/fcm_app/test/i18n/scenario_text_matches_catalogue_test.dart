import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fcm_app/i18n/scenario_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';

/// Proves the catalogue's prose reached the CSV unchanged, while the Dart it came
/// from is still there to compare against.
///
/// This whole file is deleted in the task that removes the prose from [Scenario] —
/// it exists to make that deletion safe, and it cannot outlive its oracle.
void main() {
  late Translations en;

  setUpAll(() => en = AppLocale.en.buildSync());

  test('every scenario title came across verbatim', () {
    for (final scenario in scenarioGallery) {
      expect(
        en.scenarioTitle(scenario.l10nKey),
        scenario.title,
        reason: scenario.id,
      );
    }
  });

  test('every description came across verbatim', () {
    for (final scenario in scenarioGallery) {
      expect(
        en.scenarioDescription(scenario.l10nKey),
        scenario.description,
        reason: scenario.id,
      );
    }
  });

  test('expectations match, present and absent alike', () {
    // The absent half is load-bearing: the flat map returns null for a key the CSV
    // does not have, which is what lets a missing row mean "no caveat".
    for (final scenario in scenarioGallery) {
      expect(
        en.scenarioExpectation(scenario.l10nKey),
        scenario.expectation,
        reason: scenario.id,
      );
    }
  });

  test('manual steps match, present and absent alike', () {
    for (final scenario in scenarioGallery) {
      expect(
        en.scenarioManualSteps(scenario.l10nKey),
        scenario.manualSteps,
        reason: scenario.id,
      );
    }
  });

  test('every group name came across verbatim', () {
    for (final scenario in scenarioGallery) {
      expect(
        en.scenarioGroupName(scenario.group.substring(0, 1)),
        scenario.group,
        reason: scenario.id,
      );
    }
  });

  test('every need label came across verbatim', () {
    for (final need in ScenarioNeed.values) {
      expect(en.scenarioNeedLabel(need), need.label, reason: need.name);
    }
  });
}
