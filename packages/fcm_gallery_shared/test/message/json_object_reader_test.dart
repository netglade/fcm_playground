import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  JsonObjectReader readerOf(Map<String, Object?> json) =>
      JsonObjectReader(json, path: 'message');

  Matcher throwsFormatMentioning(String fragment) => throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  group('claiming and rejecting', () {
    test('accepts an object whose every key was read', () {
      final reader = readerOf({'title': 'Hi', 'sticky': true});

      expect(reader.text('title'), 'Hi');
      expect(reader.flag('sticky'), isTrue);
      reader.requireNothingUnclaimed();
    });

    test('rejects a key nobody read, naming the field and the path', () {
      final reader = readerOf({'titel': 'Hi'});

      expect(
        reader.requireNothingUnclaimed,
        throwsFormatMentioning('message: unknown field "titel"'),
      );
    });

    test('names every unclaimed key, not just the first', () {
      final reader = readerOf({'a': 1, 'b': 2});

      expect(reader.requireNothingUnclaimed, throwsFormatMentioning('"a"'));
    });

    test('treats an absent key as null rather than an error', () {
      final reader = readerOf(const {});

      expect(reader.text('title'), isNull);
      reader.requireNothingUnclaimed();
    });
  });

  group('typed reads', () {
    test('reports a wrong type with the path and what was expected', () {
      final reader = readerOf({'title': 7});

      expect(
        () => reader.text('title'),
        throwsFormatMentioning('message.title: expected a string'),
      );
    });

    test('reads false without mistaking it for absence', () {
      expect(readerOf({'sticky': false}).flag('sticky'), isFalse);
    });

    test('reads zero without mistaking it for absence', () {
      expect(readerOf({'count': 0}).integer('count'), 0);
    });

    test('accepts an int where a number is expected', () {
      expect(readerOf({'red': 1}).number('red'), 1.0);
    });

    test('reads a list of strings', () {
      expect(
        readerOf({
          'args': ['a', 'b'],
        }).textList('args'),
        ['a', 'b'],
      );
    });

    test('rejects a list with a non-string element', () {
      final reader = readerOf({
        'args': ['a', 2],
      });

      expect(() => reader.textList('args'), throwsFormatMentioning('args'));
    });

    test('reads a string map', () {
      expect(
        readerOf({
          'data': {'k': 'v'},
        }).stringMap('data'),
        {'k': 'v'},
      );
    });

    test('rejects a string map with a non-string value', () {
      final reader = readerOf({
        'data': {'k': 1},
      });

      expect(() => reader.stringMap('data'), throwsFormatMentioning('data'));
    });

    test('reads a free-form map without inspecting its values', () {
      final payload = readerOf({
        'payload': {
          'aps': {'badge': 1},
          'custom': [1, 2],
        },
      }).freeForm('payload');

      expect(payload, {
        'aps': {'badge': 1},
        'custom': [1, 2],
      });
    });
  });

  group('nesting', () {
    test('composes the path for a nested object', () {
      final reader = readerOf({
        'android': {'titel': 'Hi'},
      });

      expect(
        () => reader.object('android', (child) {
          child.requireNothingUnclaimed();

          return 1;
        }),
        throwsFormatMentioning('message.android: unknown field "titel"'),
      );
    });

    test('rejects a non-object where an object was expected', () {
      final reader = readerOf({'android': 'nope'});

      expect(
        () => reader.object('android', (_) => 1),
        throwsFormatMentioning('message.android: expected an object'),
      );
    });
  });
}
