import 'package:fcm_app/domains/telemetry/push_telemetry.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [PushTelemetry] that keeps what it was told instead of storing or sending.
///
/// It counts flushes as well as events, because that is what distinguishes the hooks:
/// the background one must record without flushing.
class RecordingPushTelemetry implements PushTelemetry {
  /// Every event a hook recorded, in order.
  final recorded =
      <
        ({
          TelemetryEventType type,
          String traceId,
          String? scenarioId,
          String? detail,
        })
      >[];

  /// How many events had been recorded at the moment of each flush. Length is the
  /// number of flushes; the values pin the ordering.
  final recordedAtFlush = <int>[];

  /// How many times [flush] was called.
  int get flushes => recordedAtFlush.length;

  @override
  Future<void> record(
    TelemetryEventType type, {
    required String traceId,
    String? scenarioId,
    String? detail,
  }) async => recorded.add((
    type: type,
    traceId: traceId,
    scenarioId: scenarioId,
    detail: detail,
  ));

  @override
  Future<void> flush() async => recordedAtFlush.add(recorded.length);

  List<TelemetryEventType> get types => [
    for (final event in recorded) event.type,
  ];
}
