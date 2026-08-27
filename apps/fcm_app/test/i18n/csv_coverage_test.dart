import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fcm_app/i18n/translations.g.dart';

/// The CSV, checked against what was generated from it.
///
/// The generated files are committed so a fresh clone needs no codegen, at the cost
/// of the two drifting when someone edits the CSV and forgets to regenerate. This
/// makes that a failure in `melos run test`.
///
/// Reads keys rather than re-deriving slang's output — reimplementing the generator
/// to check the generator is how a test comes to agree with a bug.
void main() {
  late List<String> keys;

  setUpAll(() {
    final lines = File('lib/i18n/strings.i18n.csv').readAsLinesSync();

    expect(
      lines.first,
      'key,en,cs,(description)',
      reason:
          'the header is what stops slang reading (description) as a locale',
    );

    final rawKeys = _keysIn(lines.skip(1));
    final rawKeySet = rawKeys.toSet();
    keys = rawKeys.map((key) => _lookupKey(key, rawKeySet)).toSet().toList();
  });

  test('the CSV has rows', () {
    expect(
      keys,
      isNotEmpty,
      reason:
          'strings.i18n.csv has a header and nothing else — a merge probably '
          'dropped its rows',
    );
  });

  test('every key resolves in English', () {
    final en = AppLocale.en.buildSync();

    for (final key in keys) {
      expect(
        en[key],
        isNotNull,
        reason:
            '$key is in the CSV but not in the generated English '
            'translations — run `melos run l10n`',
      );
    }
  });

  test('every key resolves in Czech', () {
    // An empty cs cell surfaces here rather than in the UI: a missing translation
    // is a person's omission and needs a person to notice.
    final cs = AppLocale.cs.buildSync();

    for (final key in keys) {
      expect(
        cs[key],
        isNotNull,
        reason:
            '$key has no Czech translation, or `melos run l10n` was not run',
      );
    }
  });

  test('_lookupKey folds a plural row onto its shared generated function', () {
    expect(
      _lookupKey('inbox.malformed_dropped.one', {
        'inbox.malformed_dropped.one',
        'inbox.malformed_dropped.few',
        'inbox.malformed_dropped.other',
      }),
      'inbox.malformed_dropped',
      reason:
          'slang generates one function per plural, not one per CLDR '
          'category, so all three sibling rows have to resolve to the same '
          'lookup',
    );
  });

  test('_lookupKey leaves an ordinary key alone', () {
    expect(
      _lookupKey('drawer.inbox', {'drawer.inbox'}),
      'drawer.inbox',
      reason:
          "'inbox' is not a CLDR category, so a non-plural key passes "
          'through unchanged',
    );
  });

  test(
    '_lookupKey does not fold a key that merely ends in a category word',
    () {
      expect(
        _lookupKey('some.other', {'some.other'}),
        'some.other',
        reason:
            'folding on spelling alone would quietly swallow an ordinary key '
            'called `something.other`: it would be looked up as `something`, '
            'and a missing translation for it would stop failing this test. '
            'Without a sibling category present, `some.other` is not a '
            'plural and must be left as-is',
      );
    },
  );

  test('_keysIn skips a false key inside a wrapped quoted cell', () {
    // The second line resumes a wrapped quoted cell and starts with `e.g.,`,
    // which matches the row-start shape as well as a real key does.
    final keys = _keysIn([
      'a.b,English one,Czech one,"a description that wraps and resumes with',
      'e.g., a worked example"',
      'c.d,English two,Czech two,"a plain, single-line description"',
    ]);

    expect(
      keys,
      ['a.b', 'c.d'],
      reason:
          'a quote-blind scan would also report "e.g." as a third, bogus key',
    );
  });
}

final _rowStart = RegExp(r'^[a-z][a-z0-9_.]*,');

/// The keys the CSV declares, one per row *start*.
///
/// A quoted cell may hold newlines, so a line begins a row only when every quote
/// before it is closed. Shape alone is not enough — a wrapped description resuming
/// with `e.g.,` looks exactly like a key.
List<String> _keysIn(Iterable<String> rows) {
  final keys = <String>[];
  var insideQuotedCell = false;

  for (final line in rows) {
    if (!insideQuotedCell) {
      final match = _rowStart.firstMatch(line);
      if (match != null) keys.add(line.substring(0, match.end - 1));
    }

    // An odd count opens or closes a cell. Escaped quotes ("") flip parity
    // twice, so counting all of them needs no special case.
    if (line.split('"').length.isEven) {
      insideQuotedCell = !insideQuotedCell;
    }
  }

  return keys;
}

/// The CLDR categories slang treats as plural branches rather than key segments.
const _pluralCategories = {'zero', 'one', 'two', 'few', 'many', 'other'};

/// The key a row's lookup should use — a plural's rows share one generated
/// function.
///
/// Decided by whether the row has plural *siblings*, not by its last segment's
/// spelling: folding on spelling alone would swallow an ordinary key called
/// `something.other`, and stop catching a missing translation for it.
String _lookupKey(String csvKey, Set<String> allKeys) {
  final lastDot = csvKey.lastIndexOf('.');
  if (lastDot < 0) return csvKey;

  final category = csvKey.substring(lastDot + 1);
  if (!_pluralCategories.contains(category)) return csvKey;

  final parent = csvKey.substring(0, lastDot);

  // A plural always has more than one branch, so a sibling category under the
  // same parent is what tells a real plural from a key that merely ends in one.
  final hasPluralSibling = _pluralCategories
      .where((sibling) => sibling != category)
      .any((sibling) => allKeys.contains('$parent.$sibling'));

  return hasPluralSibling ? parent : csvKey;
}
