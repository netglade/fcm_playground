import 'package:fcm_app/pages/telemetry/cubit/trace_timeline.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TelemetryEvent event({
    required String traceId,
    required TelemetryEventType type,
    String deviceId = '',
    String? scenarioId,
    int minute = 30,
  }) => TelemetryEvent(
    traceId: traceId,
    type: type,
    at: DateTime.utc(2026, 8, 18, 9, minute),
    deviceId: deviceId,
    scenarioId: scenarioId,
  );

  group('groupIntoTimelines', () {
    test('keeps one timeline per trace, in the order the events arrived', () {
      final timelines = groupIntoTimelines([
        event(traceId: 't2', type: TelemetryEventType.queued, minute: 31),
        event(traceId: 't1', type: TelemetryEventType.queued, minute: 30),
      ]);

      // GET /events answers newest first, so insertion order is already the order the
      // page lists traces in — no sort, and nothing to disagree with the server about.
      expect(timelines.map((timeline) => timeline.traceId), ['t2', 't1']);
    });

    test('takes the device from whichever event has one', () {
      final timelines = groupIntoTimelines([
        // Send-side events happen on no device and carry `''`.
        event(traceId: 't1', type: TelemetryEventType.queued),
        event(
          traceId: 't1',
          type: TelemetryEventType.receivedFg,
          deviceId: 'd1',
        ),
      ]);

      // `''` is not a device. A grouping that took the first value would label every
      // trace as belonging to no handset.
      expect(timelines.single.deviceId, 'd1');
    });

    test('takes the scenario from whichever event knew it', () {
      final timelines = groupIntoTimelines([
        event(
          traceId: 't1',
          type: TelemetryEventType.receivedFg,
          deviceId: 'd1',
        ),
        event(
          traceId: 't1',
          type: TelemetryEventType.queued,
          scenarioId: 'a1_notification_only',
        ),
      ]);

      expect(timelines.single.scenarioId, 'a1_notification_only');
    });

    test('answers null for a trace nothing named a scenario or a device for', () {
      final timelines = groupIntoTimelines([
        event(traceId: 't1', type: TelemetryEventType.queued),
      ]);

      // A curl send by hand belongs to no scenario, and a send with no arrival has
      // reached no device. Null rather than `''`, so the page can say "—".
      expect(timelines.single.scenarioId, isNull);
      expect(timelines.single.deviceId, isNull);
    });

    test('finds an event by type, and says so when there is none', () {
      final timeline = groupIntoTimelines([
        event(traceId: 't1', type: TelemetryEventType.queued),
      ]).single;

      // The page draws all ten types whether or not they arrived, so this is a lookup
      // rather than a filter.
      expect(timeline.eventOf(TelemetryEventType.queued), isNotNull);
      expect(timeline.eventOf(TelemetryEventType.dismissed), isNull);
    });
  });
}
