import 'package:fcm_app/pages/sandbox/forms/path_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<MapEntry<String, String>> rows(Map<String, String> from) =>
      from.entries.toList();

  group('expandPaths', () {
    test('nests a dotted path', () {
      expect(expandPaths(rows({'aps.alert.title': 'Hi'})), {
        'aps': {
          'alert': {'title': 'Hi'},
        },
      });
    });

    test('merges rows sharing a prefix', () {
      expect(expandPaths(rows({'aps.alert.title': 'Hi', 'aps.badge': '1'})), {
        'aps': {
          'alert': {'title': 'Hi'},
          'badge': 1,
        },
      });
    });

    test('keeps a single segment at the top level', () {
      expect(expandPaths(rows({'custom': 'value'})), {'custom': 'value'});
    });

    test('reads an integer as a number, since badge is one', () {
      expect(expandPaths(rows({'aps.badge': '3'}))['aps'], {'badge': 3});
    });

    test('reads true and false as booleans', () {
      final expanded = expandPaths(
        rows({'a': 'true', 'b': 'false', 'c': 'True'}),
      );

      expect(expanded['a'], isTrue);
      expect(expanded['b'], isFalse);
      // Only the JSON spellings convert; anything else is text.
      expect(expanded['c'], 'True');
    });

    test('leaves anything else as text', () {
      expect(expandPaths(rows({'a': '1.5'}))['a'], '1.5');
      expect(expandPaths(rows({'b': 'hello'}))['b'], 'hello');
    });

    test('builds a list from numeric segments', () {
      expect(
        expandPaths(
          rows({
            'aps.alert.loc-args.0': 'first',
            'aps.alert.loc-args.1': 'second',
          }),
        ),
        {
          'aps': {
            'alert': {
              'loc-args': ['first', 'second'],
            },
          },
        },
      );
    });

    test('drops a blank path rather than making an empty key', () {
      expect(expandPaths(rows({'  ': 'orphan', 'kept': 'yes'})), {
        'kept': 'yes',
      });
    });

    test('lets a later row win when two share a path', () {
      expect(
        expandPaths([
          const MapEntry('a', 'first'),
          const MapEntry('a', 'second'),
        ]),
        {'a': 'second'},
      );
    });

    test('returns an empty map for no rows', () {
      expect(expandPaths(const []), isEmpty);
    });
  });

  group('flattenPaths', () {
    test('walks a nested map into dotted rows', () {
      final flat = flattenPaths({
        'aps': {
          'alert': {'title': 'Hi'},
          'badge': 1,
        },
      });

      expect(flat.map((row) => '${row.key}=${row.value}'), [
        'aps.alert.title=Hi',
        'aps.badge=1',
      ]);
    });

    test('indexes list elements', () {
      final flat = flattenPaths({
        'aps': {
          'alert': {
            'loc-args': ['first', 'second'],
          },
        },
      });

      expect(flat.map((row) => row.key), [
        'aps.alert.loc-args.0',
        'aps.alert.loc-args.1',
      ]);
    });

    test('returns nothing for an empty map', () {
      expect(flattenPaths(const {}), isEmpty);
    });
  });

  group('round trips', () {
    test('a realistic APNs payload survives expand after flatten', () {
      const payload = {
        'aps': {
          'alert': {
            'title': 'Build finished',
            'body': 'Release 1.0.0 is ready.',
            'loc-args': ['1.0.0'],
          },
          'badge': 1,
          'sound': 'default',
          'content-available': 1,
          'thread-id': 'builds',
        },
        'custom_key': 'kept',
      };

      expect(expandPaths(flattenPaths(payload)), payload);
    });

    test('rows survive flatten after expand', () {
      final original = rows({
        'aps.alert.title': 'Hi',
        'aps.badge': '1',
        'top': 'level',
      });

      final round = flattenPaths(expandPaths(original));

      expect(
        round.map((row) => '${row.key}=${row.value}'),
        original.map((row) => '${row.key}=${row.value}'),
      );
    });
  });
}
