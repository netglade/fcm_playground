import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const draft = NotificationDraft(
    title: 'Build finished',
    body: 'main #128 passed',
    data: {'event': 'build_finished'},
  );

  group('NotificationDraft.toJson', () {
    test('writes the flat shape the endpoint accepts', () {
      expect(draft.toJson(), {
        'title': 'Build finished',
        'body': 'main #128 passed',
        'data': {'event': 'build_finished'},
      });
    });

    test('writes an empty data map rather than omitting the key', () {
      const bare = NotificationDraft(title: 'Hi', body: 'There');

      expect(bare.toJson()['data'], isEmpty);
    });
  });

  group('NotificationDraft.fromJson', () {
    test('round-trips a draft', () {
      expect(NotificationDraft.fromJson(draft.toJson()), draft);
    });

    test('treats an absent data key as empty', () {
      final parsed = NotificationDraft.fromJson({
        'title': 'Hi',
        'body': 'There',
      });

      expect(parsed.data, isEmpty);
    });

    test(
      'treats an absent title or body as blank, for the validator to name',
      () {
        final parsed = NotificationDraft.fromJson({'body': 'There'});

        expect(parsed.title, isEmpty);
        expect(parsed.body, 'There');
      },
    );

    test('rejects a non-string title', () {
      expect(
        () => NotificationDraft.fromJson({'title': 7, 'body': 'There'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string data value, naming the key', () {
      expect(
        () => NotificationDraft.fromJson({
          'title': 'Hi',
          'body': 'There',
          'data': {'retries': 3},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('retries'),
          ),
        ),
      );
    });

    test('rejects a data value that is not an object', () {
      expect(
        () => NotificationDraft.fromJson({
          'title': 'Hi',
          'body': 'There',
          'data': 'nope',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('NotificationDraft.copyWith', () {
    test('replaces only what it is given', () {
      final edited = draft.copyWith(title: 'Build failed');

      expect(edited.title, 'Build failed');
      expect(edited.body, draft.body);
      expect(edited.data, draft.data);
    });
  });

  test('two drafts with equal contents are equal', () {
    expect(
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
    );
  });

  test('drafts differing only in a data value are not equal', () {
    expect(
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
      isNot(const NotificationDraft(title: 'a', body: 'b', data: {'k': 'w'})),
    );
  });
}
