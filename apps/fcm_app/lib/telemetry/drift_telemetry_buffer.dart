import 'package:drift/drift.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'telemetry_buffer.dart';

part 'drift_telemetry_buffer.g.dart';

/// The on-device store for telemetry events that have not reached the API yet.
///
/// It exists because the interesting moments happen when the network does not
/// work: an arrival recorded while the handset is on a train has to survive
/// until a flush succeeds, so recording and sending are separate steps with a
/// database between them.
///
/// The executor is injected rather than opened here so the tests can hand it
/// `NativeDatabase.memory()`. Opening a file path internally would make every
/// test of this class need a writable directory and a device-shaped plugin, and
/// `melos run ci` runs neither.
@DriftDatabase(tables: [BufferedEvents])
class DriftTelemetryBuffer extends _$DriftTelemetryBuffer
    implements TelemetryBuffer {
  /// Wraps [executor], which decides whether this database is a file or memory.
  DriftTelemetryBuffer(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Future<void> add(TelemetryEvent event) =>
      into(bufferedEvents).insert(_rowFor(event));

  @override
  Future<List<PendingEvent>> pending({int limit = 200}) async {
    final rows =
        await (select(bufferedEvents)
              ..orderBy([
                (row) => OrderingTerm.asc(row.atMicros),
                (row) => OrderingTerm.asc(row.id),
              ])
              ..limit(limit))
            .get();

    return [
      for (final row in rows) PendingEvent(id: row.id, event: _eventOf(row)),
    ];
  }

  @override
  Future<void> forget(List<PendingEvent> events) async {
    if (events.isEmpty) {
      // `WHERE id IN ()` is not valid SQL, and a flush that sent nothing still
      // reaches here.
      return;
    }

    final ids = [for (final event in events) event.id];
    await (delete(bufferedEvents)..where((row) => row.id.isIn(ids))).go();
  }
}

/// Events waiting to be flushed.
///
/// Named for the buffer rather than for the wire model because Drift names the
/// row class after the table in the singular: `BufferedEvents` generates
/// `BufferedEvent`, which cannot collide with the shared `TelemetryEvent` that
/// rows are mapped to and from.
///
/// The columns are the wire fields, so the mapping either side of this table is
/// a rename rather than a second definition of what an event is.
class BufferedEvents extends Table {
  /// The row identity a flush forgets by, surfaced as `PendingEvent.id`.
  ///
  /// Load-bearing rather than incidental: this buffer keeps duplicates on
  /// purpose, so this is the only thing that distinguishes two identical
  /// events, and `forget` deletes by it.
  IntColumn get id => integer().autoIncrement()();

  /// The send this event belongs to.
  TextColumn get traceId => text()();

  /// The event type's wire name, not its `Enum.index`.
  ///
  /// An index is a number whose meaning is a position in a Dart declaration, so
  /// inserting a value into `TelemetryEventType` would silently retype every
  /// buffered row. The wire name is the string both sides already agree on and
  /// is pinned by test.
  TextColumn get type => text()();

  /// When the event happened, as microseconds since the Unix epoch in UTC.
  ///
  /// Deliberately not Drift's `dateTime()`: that stores whole Unix seconds by
  /// default, which would floor every stamp and make a 300 ms delivery read as
  /// zero — the one number this pipeline exists to produce.
  ///
  /// Deliberately not ISO-8601 text either, although that is what the wire
  /// carries. `pending` sorts on this column, and `DateTime.toIso8601String`
  /// emits either three or six fractional digits, so a lexicographic sort puts
  /// `…02.000Z` *after* `…02.000001Z`. An integer sorts chronologically by
  /// construction and keeps microsecond precision.
  IntColumn get atMicros => integer()();

  /// Which install this happened on.
  TextColumn get deviceId => text()();

  /// The scenario that produced the send, when it came from the gallery.
  ///
  /// Nullable rather than defaulted to `''`: "no scenario" and "a scenario
  /// named nothing" are different answers when reading the matrix.
  TextColumn get scenarioId => text().nullable()();

  /// Whatever the event type says it carries.
  TextColumn get detail => text().nullable()();
}

/// Maps an event onto a row for insertion.
BufferedEventsCompanion _rowFor(TelemetryEvent event) =>
    BufferedEventsCompanion.insert(
      traceId: event.traceId,
      type: event.type.wireName,
      atMicros: event.at.microsecondsSinceEpoch,
      deviceId: event.deviceId,
      scenarioId: Value(event.scenarioId),
      detail: Value(event.detail),
    );

/// Rebuilds the wire model from a row.
///
/// Through `TelemetryEvent.fromJson` rather than a second constructor call, so
/// there is one definition of how a stored event becomes a `TelemetryEvent`.
/// That parser already refuses an unknown `type` instead of guessing at one,
/// keeps a null `scenario_id` distinct from `''`, and forces `at` to UTC — three
/// rules a hand-written mapper here would restate and could restate wrongly.
TelemetryEvent _eventOf(BufferedEvent row) => TelemetryEvent.fromJson({
  'trace_id': row.traceId,
  'type': row.type,
  'at': DateTime.fromMicrosecondsSinceEpoch(
    row.atMicros,
    isUtc: true,
  ).toIso8601String(),
  'device_id': row.deviceId,
  'scenario_id': row.scenarioId,
  'detail': row.detail,
});
