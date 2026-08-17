import 'package:fcm_app/pages/runs/cubit/run_timeline_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dueAt = DateTime.utc(2026, 8, 17, 9, 0, 30);

  SendMessageRequest request() => SendMessageRequest(
    target: const TokenTarget('device-token'),
    message: const FcmMessage(),
    scenarioId: 'b3_killed',
  );

  TelemetryEvent event(TelemetryEventType type) =>
      TelemetryEvent(traceId: 'tr-1', type: type, at: dueAt, deviceId: 'dev-1');

  ScheduledRun runWithEvents(List<TelemetryEvent> events) => ScheduledRun(
    id: 'run-1',
    createdAt: dueAt,
    items: [
      ScheduledRunItem(
        index: 0,
        request: request(),
        dueAt: dueAt,
        state: RunItemState.sent,
        events: events,
      ),
    ],
  );

  group('RunTimelineState', () {
    test('is not equal to itself once an item gains a telemetry event', () {
      // The item's own state stays `sent` in both — only its events differ,
      // exactly what a reload on a killed-app scenario picks up.
      final before = RunTimelineState(
        isLoading: false,
        run: runWithEvents([event(TelemetryEventType.queued)]),
      );
      final after = RunTimelineState(
        isLoading: false,
        run: runWithEvents([
          event(TelemetryEventType.queued),
          event(TelemetryEventType.receivedBg),
        ]),
      );

      expect(before, isNot(equals(after)));
    });

    test('is equal when every item has the same state and events', () {
      final first = RunTimelineState(
        isLoading: false,
        run: runWithEvents([event(TelemetryEventType.queued)]),
      );
      final second = RunTimelineState(
        isLoading: false,
        run: runWithEvents([event(TelemetryEventType.queued)]),
      );

      expect(first, equals(second));
    });
  });
}
