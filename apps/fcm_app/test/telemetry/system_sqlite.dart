import 'dart:ffi';

import 'package:sqlite3/open.dart';

/// Points the `sqlite3` package at the versioned library name, for tests.
///
/// `drift_flutter` bundles a native SQLite for a device, through
/// `sqlite3_flutter_libs`, but `flutter test` runs on the Dart VM where no
/// plugin is loaded — so a Drift test falls back to the package's own Linux
/// loader, which asks for the bare `libsqlite3.so`. Verified on this machine:
/// that name does not exist, because it comes from `libsqlite3-dev`, while
/// `libsqlite3.so.0` loads. Without this the round-trip test fails with a
/// missing shared object rather than anything about the buffer.
///
/// A deliberate copy of `useSystemSqlite` in
/// `apps/fcm_api/lib/src/sqlite_telemetry_store.dart` rather than an import of
/// it: the app does not depend on the server package, and adding that
/// dependency to reach one loader would tie the handset's build to the API's.
///
/// Both names are tried, in that order, so a machine that does have the dev
/// package is unaffected.
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
