/// The two wire shapes of the telemetry routes, as functions over JSON.
///
/// Functions rather than a class, following `path_rows.dart`: there is no state
/// here and nothing to inject. The `shelf` plumbing stays in `ApiRouter`, which
/// already turns a [FormatException] into a 400 — so everything below reports a
/// bad body by throwing one, and neither route needs a mapping of its own.
library;

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Reads the batch `POST /events` takes: `{"events": [ … ]}`.
///
/// A batch rather than one event per request because the client flushes a
/// buffer, and a request per event would multiply the failure surface by the
/// buffer size.
///
/// **The whole list is parsed before this returns, so the caller stores all of
/// it or none of it.** Partial success is the worst outcome for a client holding
/// a buffer: it cannot tell which half to keep, and would either re-send what
/// was stored or drop what was not.
///
/// An empty list is accepted — a flush of nothing is a client being tidy, not an
/// error.
List<TelemetryEvent> readEventBatch(Map<String, Object?> json) {
  final events = json['events'];
  if (events is! List) {
    throw FormatException(
      '"events" must be a list of events, got ${events.runtimeType}',
    );
  }

  return [for (final event in events) TelemetryEvent.fromJson(_object(event))];
}

/// Serialises what `GET /latency` answers with.
///
/// Each row goes through [LatencyRow.toJson] rather than being spelled out
/// again here: the app parses these rows back to draw its matrix, and two
/// spellings of one format would drift.
List<Map<String, Object?>> latencyBody(Iterable<LatencyRow> rows) => [
  for (final row in rows) row.toJson(),
];

/// Reads one member of the batch as the JSON object it has to be.
///
/// A blind cast of the list would raise a `TypeError` on `{"events": [1]}`,
/// which reaches the client as a 500 and reads as a server fault rather than as
/// the malformed body it is.
Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'every member of "events" must be an object, got ${value.runtimeType}',
    );
  }

  return value;
}
