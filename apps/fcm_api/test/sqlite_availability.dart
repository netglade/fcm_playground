import 'package:fcm_api/fcm_api.dart';
import 'package:sqlite3/sqlite3.dart';

/// Why a test that needs the native SQLite library cannot run here, or `null`
/// when it can.
///
/// A skip rather than a failure, because `melos run ci` must not depend on a native
/// library: every other test uses the in-memory store, so only the storage adapter
/// goes unexercised.
///
/// The probe opens a database rather than looking for the file, because
/// [useSystemSqlite] defers the load until the first open.
String? sqliteAvailability() {
  try {
    useSystemSqlite();
    sqlite3.openInMemory().dispose();

    return null;
  } on Object {
    return 'no system SQLite library';
  }
}
