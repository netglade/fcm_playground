import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  test('every need has a human label, since the UI shows it verbatim', () {
    for (final need in ScenarioNeed.values) {
      expect(need.label, isNotEmpty, reason: need.name);
      expect(need.label.trim(), need.label, reason: need.name);
    }
  });

  test('a scenario with no needs is supported', () {
    const scenario = Scenario(
      id: 'x',
      l10nKey: 'x',
      group: 'A',
      title: 't',
      description: 'd',
      payloadTemplate: <String, dynamic>{},
    );

    expect(scenario.needs, isEmpty);
    expect(scenario.isSupported, isTrue);
    expect(scenario.manualSteps, isNull);
    expect(scenario.target, isNull, reason: 'null means this device');
  });

  test('a scenario with a need is not supported', () {
    const scenario = Scenario(
      id: 'x',
      l10nKey: 'x',
      group: 'A',
      title: 't',
      description: 'd',
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
      title: 't',
      description: 'd',
      payloadTemplate: <String, dynamic>{},
      target: TopicTarget('news'),
    );

    expect(scenario.target, const TopicTarget('news'));
  });
}
