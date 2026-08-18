import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// One trace's events, as the Events tab draws them.
///
/// Grouped on the client rather than by the server because the grouping is a view
/// decision: the wire carries flat events, and a run's timeline groups the very same
/// events by item instead.
class TraceTimeline {
  const TraceTimeline({
    required this.traceId,
    required this.scenarioId,
    required this.deviceId,
    required this.events,
  });

  final String traceId;

  /// From whichever event knew it — the API knows it for a gallery send, the device
  /// reads it off the payload — or null when nothing did.
  final String? scenarioId;

  /// From whichever event has a non-empty one. Send-side events carry `''`, because an
  /// event recorded on the server happened on no device.
  final String? deviceId;

  /// Every event for this trace, newest first.
  final List<TelemetryEvent> events;

  /// The newest event of [type], or null when none was recorded. [events] is
  /// newest first, so the first match in that order is the newest, not the first
  /// to have happened.
  ///
  /// A trace spanning two devices holds two arrival events of the same type — a
  /// `received_fg` for each handset a broadcast reached — and the card shows only
  /// one of them.
  TelemetryEvent? eventOf(TelemetryEventType type) {
    for (final event in events) {
      if (event.type == type) {
        return event;
      }
    }

    return null;
  }
}

/// Groups [events] by trace, keeping the order they arrived in.
///
/// `GET /events` answers newest first, so insertion order into the map is already the
/// order the traces should be listed in, and each group keeps that order too. Sorting
/// here would be a second opinion about an order the server already has one about.
List<TraceTimeline> groupIntoTimelines(List<TelemetryEvent> events) {
  final byTrace = <String, List<TelemetryEvent>>{};
  for (final event in events) {
    (byTrace[event.traceId] ??= []).add(event);
  }

  return [
    for (final entry in byTrace.entries)
      TraceTimeline(
        traceId: entry.key,
        scenarioId: _firstNonBlank(
          entry.value.map((event) => event.scenarioId),
        ),
        deviceId: _firstNonBlank(entry.value.map((event) => event.deviceId)),
        events: entry.value,
      ),
  ];
}

/// The first value that is neither null nor blank, or null when there is none.
///
/// Blank counts as absent: a send-side event's `deviceId` is `''`, and treating that as
/// a device would label every trace as belonging to no handset.
String? _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}
