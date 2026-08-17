import 'package:fcm_app/telemetry/push_telemetry.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [PushTelemetry] that keeps what it was told instead of storing or sending.
///
/// It counts flushes as well as recording events, because the two are what
/// distinguish the hooks from each other: the background hook must record
/// without flushing, and "nothing was flushed" has to be provable apart from
/// "nothing was recorded".
class RecordingPushTelemetry implements PushTelemetry {
  /// Every event a hook recorded, in order. A record rather than a class so this
  /// file declares one type and a test can destructure the fields it cares
  /// about.
  final recorded =
      <
        ({
          TelemetryEventType type,
          String traceId,
          String? scenarioId,
          String? detail,
        })
      >[];

  /// How many events had been recorded at the moment of each flush.
  ///
  /// Length is the number of flushes; the values pin the ordering, so a test can
  /// tell a flush that carried an event from one that ran before it was
  /// recorded and therefore sent nothing.
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

  /// The types recorded, in order — what most assertions here are about.
  List<TelemetryEventType> get types => [
    for (final event in recorded) event.type,
  ];
}
