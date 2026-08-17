import 'dart:ffi';

import 'package:sqlite3/open.dart';

/// Points the `sqlite3` package at the versioned library name, for tests.
///
/// `flutter test` runs on the Dart VM, where `sqlite3_flutter_libs` is not loaded, so
/// a Drift test falls back to the package's own Linux loader and asks for the bare
/// `libsqlite3.so` — which only `libsqlite3-dev` installs.
///
/// A deliberate copy of `useSystemSqlite` in the API package rather than an import:
/// the app does not depend on the server, and adding that dependency to reach one
/// loader would tie the handset's build to the API's.
void useSystemSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    for (final name in const ['libsqlite3.so', 'libsqlite3.so.0']) {
      try {
        return DynamicLibrary.open(name);
      } on Object {
        continue;
      }
    }

    throw StateError(
      'No SQLite library found. Install libsqlite3-0, or libsqlite3-dev for '
      'the unversioned name.',
    );
  });
}
