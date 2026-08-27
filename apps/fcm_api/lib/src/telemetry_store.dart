import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Where telemetry events are kept, and the figure derived from them.
///
/// Two implementations because the production store is SQLite, and a native
/// library that may not be installed must not decide whether the suite can run.
/// Every behaviour here is pinned against `InMemoryTelemetryStore`.
abstract interface class TelemetryStore {
  /// Stores [events], ignoring any already stored.
  ///
  /// Idempotent on `(traceId, type, deviceId)`, deliberately excluding `at`: a
  /// retried flush may be re-stamped, and a second `received_fg` for one arrival
  /// would corrupt the one number this pipeline produces. On a shared key the
  /// earliest `at` wins.
  ///
  /// Returns how many were *newly* stored, so a retry storing none still
  /// succeeds and a client can tell suppression from a lost flush.
  Future<int> record(List<TelemetryEvent> events);

  /// Every stored event in recorded order — not `at` order, since the API stamps
  /// `queued` and `sent` from one clock reading.
  Future<List<TelemetryEvent>> all();

  /// The most recent [limit] events, newest first.
  ///
  /// Bounded, unlike [all]: a page shows what just happened, and days of records
  /// should not be read whole to answer that.
  ///
  /// [limit] must be positive, and `GET /events` is what refuses a bad one. The
  /// implementations disagree otherwise — in memory `take(-1)` throws, SQLite's
  /// `LIMIT -1` returns everything — so skipping the route's check fails
  /// differently depending on the store.
  Future<List<TelemetryEvent>> recent({int limit = 500});

  /// Every stored event belonging to one of [traceIds], in recorded order.
  ///
  /// An empty [traceIds] answers empty, not everything — the caller asked about
  /// nothing.
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
/// A SQL query would be faster but would only run where the native library is
/// installed, so `melos run ci` could not catch two definitions of "first
/// arrival" drifting apart.
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

/// Both arrival types count and have separate idempotency keys, so one trace can
/// hold a foreground *and* a background arrival for one device — which is why
/// [_keepEarliest] compares rather than trusting the key.
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

/// The scenario comes from the sender when it knew it and the device otherwise;
/// a row with neither cannot be grouped.
LatencyRow _rowFor(TelemetryEvent sent, TelemetryEvent arrival) => LatencyRow(
  traceId: sent.traceId,
  deviceId: arrival.deviceId,
  sentAt: sent.at,
  receivedAt: arrival.at,
  scenarioId: sent.scenarioId ?? arrival.scenarioId,
);
