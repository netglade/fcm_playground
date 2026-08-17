import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [TelemetryStore] that fails every write, remembering what it was asked to
/// store.
///
/// The memory tells a swallowed error from a call that was never made: an
/// implementation giving up after the first failure would still let a send succeed.
///
/// It throws synchronously rather than returning a failed future, which is the
/// harsher of the two: a `.catchError` hung off the call would not catch it.
class ThrowingTelemetryStore implements TelemetryStore {
  /// Every event [record] was handed, whether or not the call then threw.
  final attempts = <TelemetryEvent>[];

  @override
  Future<int> record(List<TelemetryEvent> events) {
    attempts.addAll(events);

    throw StateError('the telemetry database is unavailable');
  }

  @override
  Future<List<TelemetryEvent>> all() async => attempts;

  @override
  Future<List<TelemetryEvent>> eventsForTraces(List<String> traceIds) async =>
      const [];

  @override
  Future<List<LatencyRow>> latencies() async => const [];

  @override
  Future<void> close() => Future<void>.value();
}
