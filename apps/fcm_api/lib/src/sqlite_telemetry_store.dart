import 'dart:ffi';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'telemetry_store.dart';

/// The production [TelemetryStore]: one SQLite file, held open for the life of the
/// server, for the one thing `InMemoryTelemetryStore` cannot do — survive a restart.
///
/// This class owns storage, not derivation: idempotency is a primary key and one
/// conditional upsert, while the `sent → arrival` pairing is [pairLatencies], shared
/// with the in-memory store so the rule the test suite pins is the only rule there
/// is.
class SqliteTelemetryStore implements TelemetryStore {
  /// Opens the database at [path], creating the file and the table if they are not
  /// there yet. Registers the library-name override first — see [useSystemSqlite].
  factory SqliteTelemetryStore.open(String path) {
    useSystemSqlite();

    return SqliteTelemetryStore._(sqlite3.open(path));
  }

  SqliteTelemetryStore._(this._db) {
    // `at` is microseconds since the epoch rather than ISO-8601 text because the
    // earliest-wins comparison below happens in SQL: as text '…02.000001Z' sorts
    // *before* '…02.000Z', so a duplicate stamped a microsecond later would look
    // earlier and overwrite the row it duplicates.
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
    // recorded order, each event at the position of its *first* observation.
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
    // Idempotent, so a second close is not an error.
    _db.dispose();
  }

  /// [record] counts newly-stored events as the difference across the batch rather
  /// than from `changes()`: an upsert that merely refreshed a timestamp also reports
  /// one changed row, which would tell a client its retry had stored something.
  int _rowCount() =>
      _db.select('SELECT COUNT(*) AS n FROM events').first['n'] as int;
}

/// Stores an event, keeping the earliest `at` where the key already exists.
///
/// The primary key is the idempotency key, so a replayed flush conflicts rather than
/// inserting a second row. The `WHERE` is what makes the earliest observation win.
const _upsertSql = '''
INSERT INTO events (trace_id, type, device_id, at, scenario_id, detail)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT (trace_id, type, device_id) DO UPDATE SET
  at = excluded.at,
  scenario_id = excluded.scenario_id,
  detail = excluded.detail
WHERE excluded.at < events.at
''';

/// Via `fromJson` rather than a mapping of its own, so a hand-edited row with an
/// unknown `type` is refused rather than guessed at.
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
/// The package's default Linux loader tries the bare `libsqlite3.so`, which only
/// `libsqlite3-dev` installs; without this override opening a database fails at
/// startup with a message about a missing shared object rather than about SQLite.
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
