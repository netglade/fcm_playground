import 'package:fcm_api/fcm_api.dart';
import 'package:sqlite3/sqlite3.dart';

/// Why a test that needs the native SQLite library cannot run here, or `null`
/// when it can.
///
/// A skip rather than a failure, because `melos run ci` must not depend on a
/// native library being installed: the in-memory store is what every other test
/// uses, so a machine without SQLite still verifies all the behaviour — only
/// the storage adapter, and the entry point's use of it, go unexercised.
///
/// The probe opens a database rather than merely looking for the file, because
/// [useSystemSqlite] defers the load until the first open: a missing library
/// surfaces here, as a throw from `openInMemory`, and nowhere earlier.
String? sqliteAvailability() {
  try {
    useSystemSqlite();
    sqlite3.openInMemory().dispose();

    return null;
  } on Object {
    return 'no system SQLite library';
  }
}
