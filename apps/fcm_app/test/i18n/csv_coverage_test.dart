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

    // Only a line starting at column zero with a key begins a row: a quoted cell may
    // hold newlines, and those continuation lines are not keys.
    keys = [
      for (final line in lines.skip(1))
        if (RegExp(r'^[a-z][a-z0-9_.]*,').firstMatch(line) case final match?)
          line.substring(0, match.end - 1),
    ];
  });

  test('the CSV has rows', () {
    expect(keys, isNotEmpty);
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
}
