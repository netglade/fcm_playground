import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The files that must depend on nothing but `dart:core` and each other — see
/// the doc comment on `PushMessageParser` for why. They used to live in a
/// separate pure-Dart package, which enforced that by construction; folding
/// that package into the app (`a56dbdd`) kept the constraint true but took
/// away the thing that proved it. This test is what proves it now: it reads
/// each file's own `import` lines off disk and fails the moment one of them
/// names anything outside this set, which a comment alone cannot do.
const _files = [
  'push_message.dart',
  'push_message_format_exception.dart',
  'push_message_parser.dart',
  'notification_action.dart',
];

final _importLine = RegExp('''^import ['"]([^'"]+)['"]''', multiLine: true);

void main() {
  test('the dart:core-only push files import nothing but each other', () {
    for (final file in _files) {
      final source = File('lib/domains/push/$file').readAsStringSync();
      final imports = _importLine
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toList();
      final siblings = _files.where((sibling) => sibling != file).toSet();

      expect(
        imports.every(siblings.contains),
        isTrue,
        reason:
            '$file imports $imports, which strays outside dart:core and its '
            'siblings in $_files. That either breaks the property this file '
            'names in its own doc comment, or the set above needs updating '
            'alongside it.',
      );
    }
  });
}
