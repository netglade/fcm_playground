import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A way to read back what the API recorded.
///
/// The same seam as `RunScheduler` and `NotificationSender`, so no widget test
/// constructs an HTTP client. Read-only on purpose: recording is `PushTelemetry`'s job,
/// and one type that could do both would let a page write into the matrix it draws.
abstract interface class TelemetryReader {
  /// The most recent events, newest first, across every trace and device.
  Future<List<TelemetryEvent>> recentEvents({int limit = 500});

  /// One row per trace and device where both a send and an arrival are stored.
  Future<List<LatencyRow>> latencies();
}
