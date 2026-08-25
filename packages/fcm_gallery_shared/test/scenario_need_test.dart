import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  // Whether every need resolves a human label moved to
  // apps/fcm_app/test/i18n/scenario_prose_test.dart: this package has no access
  // to the translations that prose now lives in, and the label field itself is
  // gone from ScenarioNeed.

  test('a scenario with no needs is supported', () {
    const scenario = Scenario(
      id: 'x',
      l10nKey: 'x',
      group: 'A',
      payloadTemplate: <String, dynamic>{},
    );

    expect(scenario.needs, isEmpty);
    expect(scenario.isSupported, isTrue);
    expect(scenario.target, isNull, reason: 'null means this device');
  });

  test('a scenario with a need is not supported', () {
    const scenario = Scenario(
      id: 'x',
      l10nKey: 'x',
      group: 'A',
      payloadTemplate: <String, dynamic>{},
      needs: [ScenarioNeed.channels],
    );

    expect(scenario.isSupported, isFalse);
  });

  test('a scenario can name its own audience', () {
    const scenario = Scenario(
      id: 'x',
      l10nKey: 'x',
      group: 'J',
      payloadTemplate: <String, dynamic>{},
      target: TopicTarget('news'),
    );

    expect(scenario.target, const TopicTarget('news'));
  });
}
