/// The two wire shapes of the telemetry routes, as functions over JSON.
///
/// The `shelf` plumbing stays in `ApiRouter`, which already turns a
/// [FormatException] into a 400 — so everything below reports a bad body by
/// throwing one.
library;

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Reads the batch `POST /events` takes: `{"events": [ … ]}`.
///
/// The whole list is parsed before this returns, so the caller stores all of it or
/// none of it: a client holding a buffer cannot tell which half of a partial
/// success to keep. An empty list is accepted.
List<TelemetryEvent> readEventBatch(Map<String, Object?> json) {
  final events = json['events'];
  if (events is! List) {
    throw FormatException(
      '"events" must be a list of events, got ${events.runtimeType}',
    );
  }

  return [for (final event in events) TelemetryEvent.fromJson(_object(event))];
}

/// Each row goes through [LatencyRow.toJson] rather than being spelled out again
/// here: the app parses these rows back, and two spellings of one format would
/// drift.
List<Map<String, Object?>> latencyBody(Iterable<LatencyRow> rows) => [
  for (final row in rows) row.toJson(),
];

/// What `GET /events` answers with when the caller names no limit.
const defaultEventLimit = 500;

/// The most `GET /events` will answer with, however large a limit is asked for.
///
/// The whole result is decoded and held in memory at once, on both sides, so this is a
/// bound on a caller's ability to make the server do that.
const maxEventLimit = 2000;

/// Reads `?limit=`, defaulting when absent and refusing what it cannot honour.
///
/// A bad value is a [FormatException] rather than a silent fallback: someone who typed
/// `limit=abc` asked a question this cannot answer, and answering a different one
/// without saying so is worse than a 400.
int readEventLimit(String? raw) {
  if (raw == null) {
    return defaultEventLimit;
  }

  final limit = int.tryParse(raw);
  if (limit == null) {
    throw FormatException('"limit" must be a number, got "$raw"');
  }
  if (limit < 1 || limit > maxEventLimit) {
    throw FormatException(
      '"limit" must be between 1 and $maxEventLimit, got $limit',
    );
  }

  return limit;
}

/// Serialises what `GET /events` answers with.
///
/// Each event goes through [TelemetryEvent.toJson], the same shape `POST /events`
/// accepts, so the app parses back exactly the format it sends.
List<Map<String, Object?>> eventsBody(Iterable<TelemetryEvent> events) => [
  for (final event in events) event.toJson(),
];

/// A blind cast would raise a `TypeError` on `{"events": [1]}`, which reaches the
/// client as a 500 and reads as a server fault rather than a malformed body.
Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'every member of "events" must be an object, got ${value.runtimeType}',
    );
  }

  return value;
}
