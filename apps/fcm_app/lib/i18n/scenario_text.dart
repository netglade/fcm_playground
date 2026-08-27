import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// The catalogue's prose, by scenario key.
///
/// A thin typed face over slang's flat map. The map is `dynamic` because it also
/// serves plurals and parameterised strings; these six accessors are the only shapes
/// this app asks of it, and naming them once keeps the casts out of the widgets.
///
/// Hand-written rather than generated: there is nothing here a generator would know
/// that this file does not, and a generated file could not be read for the two
/// nullable returns below, which are the load-bearing part.
extension ScenarioText on Translations {
  String scenarioTitle(String key) => this['scenario.$key.title'] as String;

  String scenarioDescription(String key) =>
      this['scenario.$key.description'] as String;

  /// Null when the scenario carries no caveat — the CSV simply has no such row.
  String? scenarioExpectation(String key) =>
      this['scenario.$key.expectation'] as String?;

  /// Null when no step has to be performed by hand.
  String? scenarioManualSteps(String key) =>
      this['scenario.$key.manual_steps'] as String?;

  String scenarioGroupName(String letter) =>
      this['scenario_group.${letter.toLowerCase()}'] as String;

  /// [need.name] is camelCase for the two compound members ([ScenarioNeed.manualStep],
  /// [ScenarioNeed.externalApproval]); slang's `key_case: snake` (see `slang.yaml`)
  /// normalises every generated key to snake_case regardless of how the CSV column
  /// was spelled, so the flat map holds `scenario_need.manual_step`, never
  /// `scenario_need.manualStep`. Converting here, rather than trying to spell the
  /// CSV key to dodge the normalisation, is what keeps this a plain lookup instead
  /// of a CSV row nobody can find by reading the enum.
  String scenarioNeedLabel(ScenarioNeed need) =>
      this['scenario_need.${_snakeCase(need.name)}'] as String;
}

/// camelCase to snake_case, matching slang's own `key_case: snake` normalisation.
String _snakeCase(String camelCase) => camelCase.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match.group(0)!.toLowerCase()}',
);
