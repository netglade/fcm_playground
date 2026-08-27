/// The two wire shapes of the telemetry routes, as functions over JSON.
///
/// `ApiRouter` keeps the `shelf` plumbing and turns a [FormatException] into a
/// 400, so everything here reports a bad body by throwing one.
library;

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Reads the batch `POST /events` takes: `{"events": [ … ]}`.
///
/// The whole list is parsed before returning, so the caller stores all or none — a
/// client holding a buffer cannot tell which half of a partial success to keep. An
/// empty list is accepted.
List<TelemetryEvent> readEventBatch(Map<String, Object?> json) {
  final events = json['events'];
  if (events is! List) {
    throw FormatException(
      '"events" must be a list of events, got ${events.runtimeType}',
    );
  }

  return [for (final event in events) TelemetryEvent.fromJson(_object(event))];
}

/// Through [LatencyRow.toJson] rather than spelled out again — the app parses
/// these rows back, and two spellings would drift.
List<Map<String, Object?>> latencyBody(Iterable<LatencyRow> rows) => [
  for (final row in rows) row.toJson(),
];

/// What `GET /events` answers with when the caller names no limit.
const defaultEventLimit = 500;

/// The most `GET /events` will answer with, whatever limit is asked for.
///
/// Both sides hold the whole result in memory at once, so this bounds what a
/// caller can make the server do.
const maxEventLimit = 2000;

/// Reads `?limit=`, defaulting when absent and refusing what it cannot honour.
///
/// A bad value throws rather than falling back silently: `limit=abc` asks a
/// question this cannot answer, and quietly answering a different one is worse
/// than a 400.
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

/// Serialises what `GET /events` answers with, through [TelemetryEvent.toJson] —
/// the same shape `POST /events` accepts, so the app reads back what it sends.
List<Map<String, Object?>> eventsBody(Iterable<TelemetryEvent> events) => [
  for (final event in events) event.toJson(),
];

/// A blind cast would make `{"events": [1]}` a `TypeError`, reaching the client as
/// a 500 that reads like a server fault rather than a bad body.
Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'every member of "events" must be an object, got ${value.runtimeType}',
    );
  }

  return value;
}
