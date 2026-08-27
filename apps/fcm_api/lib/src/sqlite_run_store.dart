import 'dart:convert';
import 'dart:io';

import 'package:fcm_api/src/run_store.dart';
import 'package:fcm_api/src/sqlite_telemetry_store.dart' show useSystemSqlite;
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:sqlite3/sqlite3.dart';

/// The production [RunStore]: the same SQLite file the telemetry uses, for the one
/// thing `InMemoryRunStore` cannot do — outlive the process.
///
/// An item is stored as **its own JSON** plus two indexed columns, `due_at` and
/// `state`, which are the only fields anything queries on. One spelling of the wire
/// format rather than a column per field, so adding a field to [ScheduledRunItem]
/// does not mean a migration and a mapper that can disagree with it. The two
/// duplicated columns are written in the same statement as the JSON they come from,
/// so they cannot drift from it.
class SqliteRunStore implements RunStore {
  /// Registers the library-name override before opening — see [useSystemSqlite].
  factory SqliteRunStore.open(String path) {
    useSystemSqlite();

    return SqliteRunStore._(sqlite3.open(path));
  }

  SqliteRunStore._(this._db) {
    // Microseconds since the epoch rather than ISO-8601 text, for the reason
    // `SqliteTelemetryStore` records: text timestamps of differing precision do not
    // compare in the order they were written, and `due_at <= ?` is a comparison.
    _db
      ..execute('''
CREATE TABLE IF NOT EXISTS runs (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL
)
''')
      ..execute('''
CREATE TABLE IF NOT EXISTS run_items (
  run_id TEXT NOT NULL,
  idx INTEGER NOT NULL,
  due_at INTEGER NOT NULL,
  state TEXT NOT NULL,
  item TEXT NOT NULL,
  PRIMARY KEY (run_id, idx)
)
''')
      ..execute(
        'CREATE INDEX IF NOT EXISTS run_items_due '
        'ON run_items (state, due_at)',
      );
  }

  final Database _db;

  @override
  Future<void> save(ScheduledRun run) async {
    _db.execute('BEGIN');
    try {
      _db.execute(
        'INSERT OR REPLACE INTO runs (id, created_at) VALUES (?, ?)',
        [run.id, run.createdAt.microsecondsSinceEpoch],
      );
      for (final item in run.items) {
        _writeItem(run.id, item);
      }
      _db.execute('COMMIT');
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<ScheduledRun?> find(String id) async {
    final rows = _db.select('SELECT created_at FROM runs WHERE id = ?', [id]);
    if (rows.isEmpty) {
      return null;
    }

    return _runFrom(id, rows.first['created_at'] as int);
  }

  @override
  Future<List<ScheduledRun>> recent({int limit = 50}) async => [
    for (final row in _db.select(
      'SELECT id, created_at FROM runs ORDER BY created_at DESC, id DESC '
      'LIMIT ?',
      [limit],
    ))
      _runFrom(row['id'] as String, row['created_at'] as int),
  ];

  @override
  Future<List<ScheduledRun>> unfinished() async => [
    for (final row in _db.select(
      'SELECT r.id, r.created_at FROM runs r '
      'WHERE EXISTS (SELECT 1 FROM run_items i WHERE i.run_id = r.id '
      "AND i.state IN ('pending', 'dispatching')) "
      'ORDER BY r.created_at',
    ))
      _runFrom(row['id'] as String, row['created_at'] as int),
  ];

  /// One transaction from the read to the writes, which is what [RunStore.claimDue]
  /// requires: a cancel arriving between the two would otherwise stop an item that
  /// is already on its way.
  @override
  Future<List<ClaimedItem>> claimDue(DateTime now) async {
    final claimed = <ClaimedItem>[];
    _db.execute('BEGIN');
    try {
      final due = _db.select(
        "SELECT run_id, item FROM run_items WHERE state = 'pending' "
        'AND due_at <= ? ORDER BY due_at, run_id, idx',
        [now.microsecondsSinceEpoch],
      );
      for (final row in due) {
        final runId = row['run_id'] as String;
        final taken = _itemFrom(
          row['item'] as String,
        ).copyWith(state: RunItemState.dispatching);
        _writeItem(runId, taken);
        claimed.add((runId, taken));
      }
      _db.execute('COMMIT');
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }

    return claimed;
  }

  @override
  Future<int?> cancelPending(String runId) async {
    if (_db.select('SELECT 1 FROM runs WHERE id = ?', [runId]).isEmpty) {
      return null;
    }

    final pending = _db.select(
      "SELECT item FROM run_items WHERE run_id = ? AND state = 'pending'",
      [runId],
    );
    for (final row in pending) {
      _writeItem(
        runId,
        _itemFrom(
          row['item'] as String,
        ).copyWith(state: RunItemState.cancelled),
      );
    }

    return pending.length;
  }

  @override
  Future<void> updateItem(String runId, ScheduledRunItem item) async {
    if (_db.select('SELECT 1 FROM runs WHERE id = ?', [runId]).isNotEmpty) {
      _writeItem(runId, item);
    }
  }

  @override
  Future<void> close() async {
    // Idempotent, so a second close is not an error.
    _db.dispose();
  }

  /// The single writer, so `due_at` and `state` are never written apart from the
  /// JSON they are copied out of.
  void _writeItem(String runId, ScheduledRunItem item) => _db.execute(
    'INSERT OR REPLACE INTO run_items (run_id, idx, due_at, state, item) '
    'VALUES (?, ?, ?, ?, ?)',
    [
      runId,
      item.index,
      item.dueAt.microsecondsSinceEpoch,
      item.state.wireName,
      jsonEncode(item.toJson()),
    ],
  );

  /// Reads a run's items, skipping any this store cannot parse rather than
  /// failing the whole run — or the whole boot.
  ///
  /// This table has no migration story (`CREATE TABLE IF NOT EXISTS`) and stores
  /// each item as its own JSON blob, so a future required field on
  /// [ScheduledRunItem] would turn every existing row into a permanent
  /// `FormatException` the moment it is read. That read happens inside
  /// [unfinished], which `recover()` calls before the server ever starts
  /// serving — so letting it throw would mean one bad row keeps the process from
  /// booting at all, forever, until someone edits the database by hand. A
  /// scheduling tool that starts and reports the row it could not read is worth
  /// more than one that will not start. Nothing here writes to the database:
  /// this is a read path, and a skip must not turn into a silent mutation of
  /// data a human has not looked at yet.
  ScheduledRun _runFrom(String id, int createdAtMicros) {
    final items = <ScheduledRunItem>[];
    for (final row in _db.select(
      'SELECT idx, item FROM run_items WHERE run_id = ? ORDER BY idx',
      [id],
    )) {
      final idx = row['idx'] as int;
      try {
        items.add(_itemFrom(row['item'] as String));
      } on FormatException catch (error) {
        stderr.writeln(
          'run store: skipping unreadable item $idx of run $id: $error',
        );
      }
    }

    return ScheduledRun(
      id: id,
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        createdAtMicros,
        isUtc: true,
      ),
      items: items,
    );
  }
}

/// Through `fromJson` rather than a mapping of its own, so a hand-edited row is
/// refused rather than guessed at.
ScheduledRunItem _itemFrom(String json) =>
    ScheduledRunItem.fromJson(jsonDecode(json) as Map<String, Object?>);
