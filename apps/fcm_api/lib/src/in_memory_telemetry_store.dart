import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'telemetry_store.dart';

/// A [TelemetryStore] that keeps events in a map, for tests and for a server
/// started without a database.
///
/// It is the implementation every test in the telemetry work uses, so the whole
/// contract — idempotency, first-arrival pairing, skew — is verified in pure
/// Dart and the gate never needs a native SQLite. That makes it the definition
/// of the behaviour rather than a convenience: the SQLite store is checked
/// against these same expectations.
class InMemoryTelemetryStore implements TelemetryStore {
  /// Events by idempotency key. A `Map` rather than a list because the key *is*
  /// the deduplication, and an insertion-ordered map keeps [all] in recorded
  /// order for free — re-recording an existing key updates the value in place
  /// and leaves its position alone.
  final Map<_EventKey, TelemetryEvent> _events = {};

  @override
  Future<int> record(List<TelemetryEvent> events) async {
    var stored = 0;
    for (final event in events) {
      final key = _keyOf(event);
      final kept = _events[key];
      // Counted only when the key is new. Re-stamping an event this store already
      // holds is not a new event, so a retry reports zero rather than claiming to
      // have stored what it merely refreshed.
      if (kept == null) {
        stored++;
      }
      // Earliest wins, so a re-stamped retry cannot move an arrival later and a
      // duplicate delivery cannot inflate the latency.
      if (kept == null || event.at.isBefore(kept.at)) {
        _events[key] = event;
      }
    }

    return stored;
  }

  @override
  Future<List<TelemetryEvent>> all() async =>
      List<TelemetryEvent>.unmodifiable(_events.values);

  @override
  Future<List<LatencyRow>> latencies() async {
    final sends = <String, TelemetryEvent>{};
    final arrivals = <_PairKey, TelemetryEvent>{};
    for (final event in _events.values) {
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

  @override
  Future<void> close() => Future<void>.value();
}

/// The idempotency key: one event, whatever timestamp it is reported with.
typedef _EventKey = (String traceId, TelemetryEventType type, String deviceId);

/// What a latency row is per: one trace, one device. Both halves matter — two
/// sends to one handset are two measurements, and one send to two handsets is
/// the reason the matrix exists.
typedef _PairKey = (String traceId, String deviceId);

_EventKey _keyOf(TelemetryEvent event) =>
    (event.traceId, event.type, event.deviceId);

/// Whether this event says the message reached a device.
///
/// Both arrival types count, and they are separate keys, so one trace can hold a
/// foreground *and* a background arrival for one device — hence the comparison
/// in [_keepEarliest] rather than reliance on the idempotency key.
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
