import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Where telemetry events are kept, and the figure derived from them.
///
/// An interface with two implementations for one reason: the production store is
/// SQLite, and a native library that may not be installed must not be what
/// decides whether the test suite can run. Every behaviour below is pinned
/// against `InMemoryTelemetryStore`, and the SQLite store is checked against the
/// same expectations wherever the library happens to be present.
///
/// Nothing here can fail a send. A caller recording events is observing
/// something more important than itself, so it swallows what [record] throws —
/// losing a row is a nuisance, and failing a push because telemetry was
/// unavailable is a bug in a tool whose purpose is sending pushes.
abstract interface class TelemetryStore {
  /// Stores [events], ignoring any that is already stored.
  ///
  /// **Idempotent on `(traceId, type, deviceId)`, which deliberately excludes
  /// `at`.** A flush that succeeded server-side but whose acknowledgement was
  /// lost is retried, possibly re-stamped, and a second `received_fg` row for
  /// one arrival would corrupt the one number this pipeline exists to produce.
  /// Where two records share a key, the **earliest** `at` is the one kept: that
  /// is the first observation of the event, and for an arrival it is the
  /// time-to-first-delivery the matrix is after.
  ///
  /// A batch is accepted whole. There is no foreign key onto a send, because a
  /// push made by hand has no `queued` row here and refusing its arrival would
  /// hide a real delivery.
  /// Returns how many were **newly** stored, which is not the same as how many
  /// were given: a retried batch stores none and must still succeed. `POST
  /// /events` reports that number so a client can tell a duplicate-suppressed
  /// retry from a lost flush — the alternative, diffing [all] around the call, is
  /// linear in the store and wrong the moment two devices flush at once.
  Future<int> record(List<TelemetryEvent> events);

  /// Every stored event, in the order it was recorded.
  ///
  /// Recorded order rather than `at` order: the API stamps `queued` and `sent`
  /// from one clock reading, so ordering by time would put them in an arbitrary
  /// sequence and lose the only thing that distinguishes them.
  Future<List<TelemetryEvent>> all();

  /// One row per trace and device where both a send and an arrival are stored.
  ///
  /// Pairs `sent` with the **first** `received_fg` or `received_bg` for that
  /// trace and device. A trace with no arrival is omitted rather than reported
  /// as zero, and an arrival whose send was never recorded here is likewise
  /// omitted — there is nothing to measure from.
  Future<List<LatencyRow>> latencies();

  /// Releases whatever the implementation holds. Safe to call on a store that
  /// holds nothing.
  Future<void> close();
}

/// The one implementation of [TelemetryStore.latencies], over whatever events a
/// store holds.
///
/// Both stores call this rather than each deriving the pairing for itself. The
/// alternative for the SQLite store — the same rules again as a query — would be
/// faster on a large database, but it would run only where the native library
/// happens to be installed, so `melos run ci` could not see the two definitions
/// of "first arrival" drift apart. One definition, pinned by
/// `in_memory_telemetry_store_test.dart`, is worth more here than a query plan:
/// this is a local development tool, and the rows are one per send per device.
List<LatencyRow> pairLatencies(Iterable<TelemetryEvent> events) {
  final sends = <String, TelemetryEvent>{};
  final arrivals = <_PairKey, TelemetryEvent>{};
  for (final event in events) {
    if (event.type == TelemetryEventType.sent) {
      sends[event.traceId] = event;
    } else if (_isArrival(event.type)) {
      _keepEarliest(arrivals, event);
    }
  }

  return [
    for (final arrival in arrivals.values)
      if (sends[arrival.traceId] case final sent?) _rowFor(sent, arrival),
  ];
}

/// What a latency row is per: one trace, one device. Both halves matter — two
/// sends to one handset are two measurements, and one send to two handsets is
/// the reason the matrix exists.
typedef _PairKey = (String traceId, String deviceId);

/// Whether this event says the message reached a device.
///
/// Both arrival types count, and they are separate idempotency keys, so one trace
/// can hold a foreground *and* a background arrival for one device — hence the
/// comparison in [_keepEarliest] rather than reliance on the key.
bool _isArrival(TelemetryEventType type) =>
    type == TelemetryEventType.receivedFg ||
    type == TelemetryEventType.receivedBg;

void _keepEarliest(Map<_PairKey, TelemetryEvent> arrivals, TelemetryEvent at) {
  final key = (at.traceId, at.deviceId);
  final earliest = arrivals[key];
  if (earliest == null || at.at.isBefore(earliest.at)) {
    arrivals[key] = at;
  }
}

/// The scenario comes from the sending side when it knew it, and from the device
/// otherwise: the API knows it for a gallery send, the device reads it off the
/// payload, and a row with neither is a row nobody can group.
LatencyRow _rowFor(TelemetryEvent sent, TelemetryEvent arrival) => LatencyRow(
  traceId: sent.traceId,
  deviceId: arrival.deviceId,
  sentAt: sent.at,
  receivedAt: arrival.at,
  scenarioId: sent.scenarioId ?? arrival.scenarioId,
);
