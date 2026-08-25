import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fcm_app/i18n/translations.g.dart';

/// The CSV, checked against what was generated from it.
///
/// The generated files are committed so a fresh clone needs no codegen step; the
/// cost is that editing the CSV and forgetting to regenerate leaves the two out of
/// step. This turns that into a failure in `melos run test`, which is where whoever
/// edited the CSV will be looking.
///
/// It reads keys rather than re-deriving slang's output: reimplementing the
/// generator to check the generator is how a test comes to agree with a bug.
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

    keys = _keysIn(lines.skip(1));
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
    // An empty cs cell surfaces here rather than in the UI. slang has no fallback
    // worth relying on: a missing translation is a person's omission and needs a
    // person to notice it.
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

  test('_keysIn skips a false key inside a wrapped quoted cell', () {
    // The second line resumes a quoted cell that wrapped, and starts with `e.g.,` —
    // which matches the row-start shape just as well as a real key does. A naive
    // line-by-line regex would return three keys, the middle one bogus.
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
/// A quoted cell may hold newlines, so a physical line begins a row only when every
/// quote before it is closed. Matching the line's shape alone is not enough: a
/// description that wrapped and resumed with `e.g.,` looks exactly like a key, and
/// would fail this test for a key that never existed.
List<String> _keysIn(Iterable<String> rows) {
  final keys = <String>[];
  var insideQuotedCell = false;

  for (final line in rows) {
    if (!insideQuotedCell) {
      final match = _rowStart.firstMatch(line);
      if (match != null) keys.add(line.substring(0, match.end - 1));
    }

    // An odd number of quotes on a line opens or closes a cell. Escaped quotes ("")
    // flip parity twice, so counting every quote is right without special-casing them.
    if (line.split('"').length.isEven) {
      insideQuotedCell = !insideQuotedCell;
    }
  }

  return keys;
}
