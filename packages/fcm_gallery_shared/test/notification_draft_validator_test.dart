import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const validator = NotificationDraftValidator();

  NotificationDraft draft({
    String title = 'Build finished',
    String body = 'main #128 passed',
    Map<String, String> data = const {},
  }) => NotificationDraft(title: title, body: body, data: data);

  group('NotificationDraftValidator.validate', () {
    test('accepts a well-formed draft', () {
      expect(validator.validate(draft()), isEmpty);
    });

    test('accepts extra data keys that collide with nothing', () {
      expect(
        validator.validate(draft(data: {'event': 'build_finished'})),
        isEmpty,
      );
    });

    test('rejects a blank title against the title field', () {
      final problems = validator.validate(draft(title: '   '));

      expect(problems, [const DraftProblem('title', 'must not be blank')]);
    });

    test('rejects a blank body against the body field', () {
      final problems = validator.validate(draft(body: ''));

      expect(problems, [const DraftProblem('body', 'must not be blank')]);
    });

    test('reports a blank title and a blank body together', () {
      expect(validator.validate(draft(title: '', body: '')), hasLength(2));
    });

    test('rejects a blank data key', () {
      final problems = validator.validate(draft(data: {'  ': 'v'}));

      expect(problems, [const DraftProblem('data', 'has a blank key')]);
    });

    test('rejects a data key that collides with a reserved payload key', () {
      final problems = validator.validate(draft(data: {'sentAt': 'now'}));

      expect(problems, [
        const DraftProblem(
          'data.sentAt',
          'collides with a reserved payload key',
        ),
      ]);
    });

    test('rejects every reserved key, so the rule cannot rot as core changes', () {
      for (final reserved in PushMessageParser.reservedKeys) {
        expect(
          validator.validate(draft(data: {reserved: 'x'})),
          hasLength(1),
          reason: '$reserved should be rejected',
        );
      }
    });

    test('returns an unmodifiable list', () {
      expect(
        () => validator.validate(draft()).add(const DraftProblem('a', 'b')),
        throwsUnsupportedError,
      );
    });
  });

  group('NotificationDraftValidator.validateEntries', () {
    test('rejects a duplicated key, which a map could not have shown', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [MapEntry('event', 'a'), MapEntry('event', 'b')],
      );

      expect(problems, [const DraftProblem('data.event', 'is duplicated')]);
    });

    test('reports the collision once, not once per repeat', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [
          MapEntry('event', 'a'),
          MapEntry('event', 'b'),
          MapEntry('event', 'c'),
        ],
      );

      expect(problems, hasLength(2));
    });

    test('accepts distinct keys', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [MapEntry('event', 'a'), MapEntry('deepLink', '/b')],
      );

      expect(problems, isEmpty);
    });
  });
}
