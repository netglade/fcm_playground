import 'dart:ffi';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'telemetry_store.dart';

/// The production [TelemetryStore]: one SQLite file, held open for the life of
/// the server.
///
/// It exists for the one thing `InMemoryTelemetryStore` cannot do — survive a
/// restart. A matrix that forgot every send whenever the server was restarted
/// would be useless for the delayed and killed-app scenarios, whose whole point
/// is that the interesting moment happens minutes after the send.
///
/// **This class owns storage, not derivation.** Idempotency is a primary key and
/// one conditional upsert; the `sent → arrival` pairing is [pairLatencies],
/// shared with the in-memory store, so the rule the test suite pins is the only
/// rule that exists. Reading every row to pair in Dart is slower than pairing in
/// SQL, and that is the trade taken deliberately: a second copy of the pairing
/// written in SQL would run only where the native library happens to be
/// installed, so `melos run ci` could not see it drift.
class SqliteTelemetryStore implements TelemetryStore {
  /// Opens the database at [path], creating the file and the table if they are
  /// not there yet.
  ///
  /// Registers the library-name override first, because the default loader on
  /// Linux looks for a name that is not always present — see [useSystemSqlite].
  factory SqliteTelemetryStore.open(String path) {
    useSystemSqlite();

    return SqliteTelemetryStore._(sqlite3.open(path));
  }

  SqliteTelemetryStore._(this._db) {
    // `IF NOT EXISTS`, and no migration: this is the first schema, and a step
    // that dropped the table would lose every send on every restart.
    //
    // `at` is microseconds since the epoch rather than ISO-8601 text because the
    // earliest-wins comparison below happens in SQL. Dart writes a fractional
    // second only as wide as it needs, so as text '…02.000001Z' sorts *before*
    // '…02.000Z' — '0' precedes 'Z' — and a duplicate stamped a microsecond
    // later would look earlier and overwrite the row it duplicates. An integer
    // also cannot carry an offset, so a local time cannot be stored by mistake.
    _db.execute('''
CREATE TABLE IF NOT EXISTS events (
  trace_id TEXT NOT NULL,
  type TEXT NOT NULL,
  device_id TEXT NOT NULL,
  at INTEGER NOT NULL,
  scenario_id TEXT,
  detail TEXT,
  PRIMARY KEY (trace_id, type, device_id)
)
''');
  }

  final Database _db;

  @override
  Future<int> record(List<TelemetryEvent> events) async {
    final before = _rowCount();
    final upsert = _db.prepare(_upsertSql);
    _db.execute('BEGIN');
    try {
      for (final event in events) {
        upsert.execute([
          event.traceId,
          event.type.wireName,
          event.deviceId,
          event.at.microsecondsSinceEpoch,
          event.scenarioId,
          event.detail,
        ]);
      }
      _db.execute('COMMIT');
    } on Object {
      // A batch is accepted whole, so a failure half way through leaves the
      // client's buffer describing exactly what still needs sending.
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      upsert.dispose();
    }

    return _rowCount() - before;
  }

  @override
  Future<List<TelemetryEvent>> all() async => [
    // `rowid` is assigned on insert and an upsert leaves it alone, so this is
    // recorded order with each event at the position of its *first* observation
    // — the same order the in-memory store's insertion-ordered map gives.
    // Ordering by `at` instead would put `queued` and `sent`, stamped from one
    // clock reading, into an arbitrary sequence.
    for (final row in _db.select(
      'SELECT trace_id, type, device_id, at, scenario_id, detail '
      'FROM events ORDER BY rowid',
    ))
      _eventFrom(row),
  ];

  @override
  Future<List<LatencyRow>> latencies() async => pairLatencies(await all());

  @override
  Future<void> close() async {
    // Idempotent, so a second close — or a close of a store whose database was
    // already released — is not an error.
    _db.dispose();
  }

  /// How many events the table holds.
  ///
  /// [record] counts newly-stored events as the difference across the batch
  /// rather than from `changes()`: an upsert that merely refreshed a timestamp
  /// also reports one changed row, which would tell a client its retry had
  /// stored something.
  int _rowCount() =>
      _db.select('SELECT COUNT(*) AS n FROM events').first['n'] as int;
}

/// Stores an event, keeping the earliest `at` where the key already exists.
///
/// The primary key is the idempotency key, so a replayed flush conflicts rather
/// than inserting a second row for one arrival. The `WHERE` is what makes the
/// earliest observation win: a retry stamped later leaves the stored row alone,
/// and one stamped earlier replaces it whole — a re-stamped duplicate can move
/// an arrival earlier but never later, which is the figure the matrix wants.
const _upsertSql = '''
INSERT INTO events (trace_id, type, device_id, at, scenario_id, detail)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT (trace_id, type, device_id) DO UPDATE SET
  at = excluded.at,
  scenario_id = excluded.scenario_id,
  detail = excluded.detail
WHERE excluded.at < events.at
''';

/// Rebuilds an event from a row, through the same parser the wire format uses.
///
/// Deliberately via `fromJson` rather than a second mapping of its own: the wire
/// name of a type is matched in exactly one place, so a hand-edited or
/// half-written row with an unknown `type` is refused here in the same way a
/// malformed request is refused at the endpoint, instead of being guessed at.
TelemetryEvent _eventFrom(Row row) => TelemetryEvent.fromJson(<String, Object?>{
  'trace_id': row['trace_id'],
  'type': row['type'],
  'at': DateTime.fromMicrosecondsSinceEpoch(
    row['at'] as int,
    isUtc: true,
  ).toIso8601String(),
  'device_id': row['device_id'],
  'scenario_id': row['scenario_id'],
  'detail': row['detail'],
});

/// Points the `sqlite3` package at the versioned library name.
///
/// Verified on this machine: `libsqlite3.so` does not exist — that bare symlink
/// comes from `libsqlite3-dev`, which is not installed — while `libsqlite3.so.0`
/// loads. The package's default Linux loader tries the bare name, so without this
/// override opening a database fails at startup with a message about a missing
/// shared object rather than anything about SQLite.
///
/// Both names are tried, in that order, so a machine that does have the dev
/// package is unaffected. It lives beside [SqliteTelemetryStore] rather than in a
/// file of its own because it exists solely so that store can be opened, and
/// because `prefer-match-file-name` pins a file's name to the first class
/// declared in it — which this file's is.
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
