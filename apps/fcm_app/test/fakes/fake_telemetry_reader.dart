import 'package:fcm_app/domains/telemetry/entities/telemetry_reader.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_reader_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [TelemetryReader] driven by the test rather than by the API.
class FakeTelemetryReader implements TelemetryReader {
  FakeTelemetryReader({
    this.events = const [],
    this.rows = const [],
    this.failure,
  });

  /// What [recentEvents] answers when [failure] is null.
  final List<TelemetryEvent> events;

  /// What [latencies] answers when [failure] is null.
  final List<LatencyRow> rows;

  /// Thrown by both reads when set.
  final TelemetryReaderException? failure;

  @override
  Future<List<TelemetryEvent>> recentEvents({int limit = 500}) async {
    if (failure case final failure?) {
      throw failure;
    }

    return events;
  }

  @override
  Future<List<LatencyRow>> latencies() async {
    if (failure case final failure?) {
      throw failure;
    }

    return rows;
  }
}
