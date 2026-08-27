import 'dart:ffi';

import 'package:fcm_api/src/telemetry_store.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// The production [TelemetryStore]: one SQLite file held open for the life of the
/// server, for what `InMemoryTelemetryStore` cannot do — survive a restart.
///
/// Owns storage, not derivation. Idempotency is a primary key and one conditional
/// upsert; the `sent → arrival` pairing is [pairLatencies], shared with the
/// in-memory store so the pinned rule is the only rule.
class SqliteTelemetryStore implements TelemetryStore {
  /// Opens the database at [path], creating the file and the table if they are not
  /// there yet. Registers the library-name override first — see [useSystemSqlite].
  factory SqliteTelemetryStore.open(String path) {
    useSystemSqlite();

    return SqliteTelemetryStore._(sqlite3.open(path));
  }

  SqliteTelemetryStore._(this._db) {
    // Microseconds, not ISO-8601 text, because the earliest-wins comparison
    // happens in SQL: as text '…02.000001Z' sorts *before* '…02.000Z', so a
    // later duplicate would look earlier and overwrite the original.
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
      // A batch is accepted whole, so a mid-way failure leaves the client's
      // buffer describing exactly what still needs sending.
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      upsert.dispose();
    }

    return _rowCount() - before;
  }

  @override
  Future<List<TelemetryEvent>> all() async => [
    // `rowid` is assigned on insert and untouched by an upsert, so this is
    // recorded order — each event at its *first* observation.
    for (final row in _db.select(
      'SELECT trace_id, type, device_id, at, scenario_id, detail '
      'FROM events ORDER BY rowid',
    ))
      _eventFrom(row),
  ];

  @override
  Future<List<TelemetryEvent>> recent({int limit = 500}) async => [
    // `rowid` DESC is the same "newest first" the in-memory store gets by
    // reversing its insertion-ordered map.
    for (final row in _db.select(
      'SELECT trace_id, type, device_id, at, scenario_id, detail '
      'FROM events ORDER BY rowid DESC LIMIT ?',
      [limit],
    ))
      _eventFrom(row),
  ];

  /// `rowid` order is recorded order, as in [all]. Placeholders are built from
  /// the list's length, never interpolated, so a trace id cannot be SQL.
  @override
  Future<List<TelemetryEvent>> eventsForTraces(List<String> traceIds) async {
    if (traceIds.isEmpty) {
      return const [];
    }

    final placeholders = List.filled(traceIds.length, '?').join(', ');

    return [
      for (final row in _db.select(
        'SELECT trace_id, type, device_id, at, scenario_id, detail '
        'FROM events WHERE trace_id IN ($placeholders) ORDER BY rowid',
        traceIds,
      ))
        _eventFrom(row),
    ];
  }

  @override
  Future<List<LatencyRow>> latencies() async => pairLatencies(await all());

  @override
  Future<void> close() async {
    // Idempotent, so a second close is not an error.
    _db.dispose();
  }

  /// [record] counts new events as the difference across the batch, not from
  /// `changes()`: an upsert that merely refreshed a timestamp also reports one
  /// changed row, telling a client its retry stored something.
  int _rowCount() =>
      _db.select('SELECT COUNT(*) AS n FROM events').first['n'] as int;
}

/// Stores an event, keeping the earliest `at` where the key already exists.
///
/// The primary key *is* the idempotency key, so a replayed flush conflicts rather
/// than inserting again. The `WHERE` makes the earliest observation win.
const _upsertSql = '''
INSERT INTO events (trace_id, type, device_id, at, scenario_id, detail)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT (trace_id, type, device_id) DO UPDATE SET
  at = excluded.at,
  scenario_id = excluded.scenario_id,
  detail = excluded.detail
WHERE excluded.at < events.at
''';

/// Via `fromJson`, so a hand-edited row with an unknown `type` is refused rather
/// than guessed at.
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
/// Its default Linux loader tries the bare `libsqlite3.so`, which only
/// `libsqlite3-dev` installs — so without this, opening a database fails with a
/// missing-shared-object message that never mentions SQLite.
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
