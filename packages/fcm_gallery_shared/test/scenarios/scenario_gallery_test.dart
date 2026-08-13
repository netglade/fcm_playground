import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  test('every id is unique', () {
    final ids = scenarioGallery.map((s) => s.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test("every id starts with its group's letter", () {
    // The one assertion that catches an entry filed under the wrong table as
    // eleven files grow independently.
    for (final scenario in scenarioGallery) {
      final letter = scenario.group.substring(0, 1).toLowerCase();
      expect(
        scenario.id,
        startsWith(letter),
        reason: '${scenario.id} is filed under ${scenario.group}',
      );
    }
  });

  test('every template round-trips through the typed model', () {
    // 66 hand-written templates is exactly where a `titel` typo or a camelCase
    // key slips in. The strict parser plus this assertion turns that into a
    // failed build rather than an opaque 400 from Google on a device.
    for (final scenario in scenarioGallery) {
      final raw = Map<String, Object?>.from(scenario.payloadTemplate);
      expect(FcmMessage.fromJson(raw).toJson(), raw, reason: scenario.id);
    }
  });

  test('no template sets its own delivery target', () {
    for (final scenario in scenarioGallery) {
      for (final key in const ['token', 'topic', 'condition']) {
        expect(
          scenario.payloadTemplate.containsKey(key),
          isFalse,
          reason: '${scenario.id} sets $key; use Scenario.target instead',
        );
      }
    }
  });

  test('every scenario has a non-blank title and description', () {
    for (final scenario in scenarioGallery) {
      expect(scenario.title.trim(), isNotEmpty, reason: scenario.id);
      expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
    }
  });

  test('a manual-step scenario says what the step is', () {
    for (final scenario in scenarioGallery) {
      if (scenario.needs.contains(ScenarioNeed.manualStep)) {
        expect(scenario.manualSteps, isNotNull, reason: scenario.id);
      }
    }
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
      expect(dataOnly.requiresKilledApp, isTrue);
    });

    test('the hybrid scenario carries both blocks', () {
      final hybrid = groupA.firstWhere((s) => s.id == 'a3_hybrid');

      expect(hybrid.payloadTemplate['notification'], isNotNull);
      expect(hybrid.payloadTemplate['data'], isNotNull);
    });
  });
}
