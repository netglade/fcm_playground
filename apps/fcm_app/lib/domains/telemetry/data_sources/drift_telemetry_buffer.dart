import 'package:drift/drift.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import '../entities/telemetry_buffer.dart';

part 'drift_telemetry_buffer.g.dart';

/// The on-device store for telemetry events that have not reached the API yet.
///
/// The executor is injected rather than opened here so the tests can hand it
/// `NativeDatabase.memory()` — a file path would make every test of this class
/// need a writable directory and a device-shaped plugin.
@DriftDatabase(tables: [BufferedEvents])
class DriftTelemetryBuffer extends _$DriftTelemetryBuffer
    implements TelemetryBuffer {
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
/// `BufferedEvent`, which cannot collide with the shared `TelemetryEvent`.
class BufferedEvents extends Table {
  /// Surfaced as `PendingEvent.id`. Load-bearing: this buffer keeps duplicates on
  /// purpose, so this is the only thing that distinguishes two identical events.
  IntColumn get id => integer().autoIncrement()();

  TextColumn get traceId => text()();

  /// The event type's wire name, not its `Enum.index` — an index means a position
  /// in a Dart declaration, so inserting a value into `TelemetryEventType` would
  /// silently retype every buffered row.
  TextColumn get type => text()();

  /// Microseconds since the Unix epoch in UTC.
  ///
  /// Not Drift's `dateTime()`, which stores whole seconds and would make a 300 ms
  /// delivery read as zero. Not ISO-8601 text either: `pending` sorts on this
  /// column, and `toIso8601String` emits three or six fractional digits, so a
  /// lexicographic sort puts `…02.000Z` *after* `…02.000001Z`.
  IntColumn get atMicros => integer()();

  TextColumn get deviceId => text()();

  /// Nullable rather than defaulted to `''`: "no scenario" and "a scenario named
  /// nothing" are different answers when reading the matrix.
  TextColumn get scenarioId => text().nullable()();

  TextColumn get detail => text().nullable()();
}

BufferedEventsCompanion _rowFor(TelemetryEvent event) =>
    BufferedEventsCompanion.insert(
      traceId: event.traceId,
      type: event.type.wireName,
      atMicros: event.at.microsecondsSinceEpoch,
      deviceId: event.deviceId,
      scenarioId: Value(event.scenarioId),
      detail: Value(event.detail),
    );

/// Rebuilds the wire model from a row through `TelemetryEvent.fromJson` rather
/// than a second constructor call: that parser already refuses an unknown `type`,
/// keeps a null `scenario_id` distinct from `''`, and forces `at` to UTC.
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
