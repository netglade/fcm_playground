import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Where telemetry events are kept, and the figure derived from them.
///
/// Two implementations for one reason: the production store is SQLite, and a
/// native library that may not be installed must not decide whether the test suite
/// can run. Every behaviour below is pinned against `InMemoryTelemetryStore`.
abstract interface class TelemetryStore {
  /// Stores [events], ignoring any that is already stored.
  ///
  /// Idempotent on `(traceId, type, deviceId)`, deliberately excluding `at`: a
  /// flush whose acknowledgement was lost is retried, possibly re-stamped, and a
  /// second `received_fg` row for one arrival would corrupt the one number this
  /// pipeline exists to produce. Where two records share a key the earliest `at`
  /// wins, since that is the first observation.
  ///
  /// Returns how many were *newly* stored — a retried batch stores none and must
  /// still succeed, and `POST /events` reports the number so a client can tell a
  /// duplicate-suppressed retry from a lost flush.
  Future<int> record(List<TelemetryEvent> events);

  /// Every stored event, in the order it was recorded — not `at` order, because
  /// the API stamps `queued` and `sent` from one clock reading.
  Future<List<TelemetryEvent>> all();

  /// The most recent [limit] events, newest first.
  ///
  /// Newest first and bounded, unlike [all]: a page shows the last thing that happened,
  /// and a store that has been recording for days should not be read whole to answer
  /// that. [limit] must be positive — `GET /events` is what refuses a caller's bad one,
  /// so this does not repeat the check. The two implementations disagree on what a bad
  /// value does anyway: in memory, `take(-1)` throws a `RangeError`, while SQLite's
  /// `LIMIT -1` answers the whole table — a caller that skipped the route's check
  /// would see a different failure, or none, depending on which store is behind it.
  Future<List<TelemetryEvent>> recent({int limit = 500});

  /// Every stored event belonging to one of [traceIds], in recorded order.
  ///
  /// Narrower than [all] because a run's timeline asks about six traces and reading
  /// an entire database to answer that is not a query. An empty [traceIds] answers
  /// empty rather than everything — the caller asked about nothing.
  Future<List<TelemetryEvent>> eventsForTraces(List<String> traceIds);

  /// One row per trace and device where both a send and an arrival are stored,
  /// pairing `sent` with the *first* arrival. A trace with no arrival is omitted
  /// rather than reported as zero.
  Future<List<LatencyRow>> latencies();

  /// Safe to call on a store that holds nothing.
  Future<void> close();
}

/// The one implementation of [TelemetryStore.latencies], called by both stores.
///
/// The same rules as a SQL query would be faster on a large database, but would run
/// only where the native library is installed, so `melos run ci` could not see the
/// two definitions of "first arrival" drift apart.
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

/// One trace, one device. Both halves matter: two sends to one handset are two
/// measurements, and one send to two handsets is why the matrix exists.
typedef _PairKey = (String traceId, String deviceId);

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
