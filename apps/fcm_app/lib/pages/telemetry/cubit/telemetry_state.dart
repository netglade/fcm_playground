import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'trace_timeline.dart';

/// What the telemetry page is showing.
///
/// Value-equal, like `RunsState` and unlike `SandboxState`: nothing here is republished
/// on every keystroke, so dropping a state equal to the current one is exactly right.
/// Compared by trace and row identity and count — `traceId`/`deviceId` plus how many
/// events or which `receivedAt` each carries — rather than by list identity, which
/// would call two identical loads different. Not by everything the page draws:
/// timestamps, `detail` and `sentAt` are drawn but left out of the comparison. That is
/// safe only because the store is append-only and keeps the earliest stamp per key, so
/// a key that still matches cannot have grown a different value underneath it.
class TelemetryState {
  const TelemetryState({
    this.isLoading = true,
    this.traces = const [],
    this.latencies = const [],
    this.error,
  });

  final bool isLoading;

  /// Newest trace first.
  final List<TraceTimeline> traces;

  final List<LatencyRow> latencies;

  /// Safe to show as-is, or null when the load worked.
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is TelemetryState &&
      isLoading == other.isLoading &&
      error == other.error &&
      _sameTraces(traces, other.traces) &&
      _sameRows(latencies, other.latencies);

  @override
  int get hashCode => Object.hash(
    isLoading,
    error,
    Object.hashAll(traces.map(_hashTrace)),
    Object.hashAll(latencies.map(_hashRow)),
  );
}

bool _sameTraces(List<TraceTimeline> a, List<TraceTimeline> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index].traceId != b[index].traceId ||
        a[index].events.length != b[index].events.length) {
      return false;
    }
  }

  return true;
}

bool _sameRows(List<LatencyRow> a, List<LatencyRow> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index].traceId != b[index].traceId ||
        a[index].deviceId != b[index].deviceId ||
        a[index].receivedAt != b[index].receivedAt) {
      return false;
    }
  }

  return true;
}

int _hashTrace(TraceTimeline timeline) =>
    Object.hash(timeline.traceId, timeline.events.length);

int _hashRow(LatencyRow row) =>
    Object.hash(row.traceId, row.deviceId, row.receivedAt);
