import 'package:drift/drift.dart';

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
///
/// This is the schema's first step, and holds only what Task 10 needs to prove
/// codegen works end to end — the buffer's behaviour arrives in Task 11.
@DriftDatabase(tables: [BufferedEvents])
class DriftTelemetryBuffer extends _$DriftTelemetryBuffer {
  /// Wraps [executor], which decides whether this database is a file or memory.
  DriftTelemetryBuffer(super.executor);

  @override
  int get schemaVersion => 1;

  /// Stores one trace id.
  Future<void> recordTrace(String traceId) => into(
    bufferedEvents,
  ).insert(BufferedEventsCompanion.insert(traceId: traceId));

  /// Every stored trace id, in insertion order.
  Future<List<String>> traces() async => [
    for (final row in await select(bufferedEvents).get()) row.traceId,
  ];
}

/// Events waiting to be flushed.
///
/// Named for the buffer rather than for the wire model because Drift names the
/// row class after the table in the singular: `BufferedEvents` generates
/// `BufferedEvent`, which cannot collide with the shared `TelemetryEvent` that
/// Task 11 maps rows to and from.
class BufferedEvents extends Table {
  /// Insertion order, which is the order a flush should send in — the wall
  /// clock on a device can move backwards.
  IntColumn get id => integer().autoIncrement()();

  /// The send this event belongs to.
  TextColumn get traceId => text()();
}
