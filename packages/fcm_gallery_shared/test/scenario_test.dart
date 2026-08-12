import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('scenarioGallery', () {
    test('offers the nine scenarios the Sandbox lists', () {
      expect(scenarioGallery, hasLength(9));
    });

    test('gives every scenario a unique id', () {
      final ids = scenarioGallery.map((scenario) => scenario.id).toSet();

      expect(ids, hasLength(scenarioGallery.length));
    });

    test('files every scenario under a non-blank group', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.group.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test('gives every scenario a title, description and at least one tag', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.title.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.tags, isNotEmpty, reason: scenario.id);
      }
    });

    test('every template parses as an FCM message', () {
      for (final scenario in scenarioGallery) {
        expect(
          () => FcmMessage.fromJson(scenario.payloadTemplate),
          returnsNormally,
          reason: scenario.id,
        );
      }
    });

    test('every template round-trips unchanged, so nothing is dropped', () {
      for (final scenario in scenarioGallery) {
        expect(
          FcmMessage.fromJson(scenario.payloadTemplate).toJson(),
          scenario.payloadTemplate,
          reason: scenario.id,
        );
      }
    });

    test('no template sets a delivery target', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.payloadTemplate.keys, isNot(contains('token')));
        expect(scenario.payloadTemplate.keys, isNot(contains('topic')));
        expect(scenario.payloadTemplate.keys, isNot(contains('condition')));
      }
    });

    test('covers more than one group', () {
      final groups = scenarioGallery.map((scenario) => scenario.group).toSet();

      expect(groups, hasLength(greaterThan(1)));
    });

    test('the data-only scenario really carries no notification', () {
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'data_only',
      );

      expect(dataOnly.payloadTemplate.keys, contains('data'));
      expect(dataOnly.payloadTemplate.keys, isNot(contains('notification')));
      expect(dataOnly.requiresKilledApp, isTrue);
    });

    test('a scenario that needs a killed app asks for a delay', () {
      for (final scenario in scenarioGallery) {
        if (scenario.requiresKilledApp) {
          expect(
            scenario.defaultDelaySeconds,
            greaterThan(0),
            reason:
                '${scenario.id} cannot be demonstrated without time to kill '
                'the app',
          );
        }
      }
    });
  });
}
