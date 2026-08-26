import 'package:fcm_app/domains/telemetry/telemetry_reader_exception.dart';
import 'package:fcm_app/pages/telemetry/cubit/telemetry_cubit.dart';
import 'package:fcm_app/pages/telemetry/cubit/telemetry_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_telemetry_reader.dart';

void main() {
  TelemetryEvent event(String traceId, TelemetryEventType type) =>
      TelemetryEvent(
        traceId: traceId,
        type: type,
        at: DateTime.utc(2026, 8, 18, 9, 30),
        deviceId: 'd1',
      );

  group('TelemetryCubit', () {
    test('starts loading, with nothing to show', () {
      final cubit = TelemetryCubit(FakeTelemetryReader());
      addTearDown(cubit.close);

      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.traces, isEmpty);
    });

    test('publishes the grouped traces and the rows together', () async {
      final cubit = TelemetryCubit(
        FakeTelemetryReader(
          events: [
            event('t1', TelemetryEventType.queued),
            event('t1', TelemetryEventType.receivedFg),
            event('t2', TelemetryEventType.queued),
          ],
          rows: [
            LatencyRow(
              traceId: 't1',
              deviceId: 'd1',
              sentAt: DateTime.utc(2026, 8, 18, 9, 30),
              receivedAt: DateTime.utc(2026, 8, 18, 9, 30, 0, 300),
              scenarioId: null,
            ),
          ],
        ),
      );
      addTearDown(cubit.close);

      await cubit.load();

      // Both tabs from one load: two requests to a loopback server race for nothing,
      // and a page with one refresh button must not leave half of itself stale.
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.traces.map((timeline) => timeline.traceId), [
        't1',
        't2',
      ]);
      expect(cubit.state.latencies, hasLength(1));
      expect(cubit.state.error, isNull);
    });

    test('a failure becomes a message rather than a throw', () async {
      final cubit = TelemetryCubit(
        FakeTelemetryReader(
          failure: const TelemetryReaderException('the API is not running'),
        ),
      );
      addTearDown(cubit.close);

      // Expected rather than exceptional: the API is a local process somebody has to
      // have started, so this is a line on the screen.
      await cubit.load();

      expect(cubit.state.error, 'the API is not running');
      expect(cubit.state.isLoading, isFalse);
    });

    test('a reload shows the spinner again', () async {
      final cubit = TelemetryCubit(FakeTelemetryReader());
      addTearDown(cubit.close);
      await cubit.load();

      final states = <TelemetryState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);
      await cubit.load();

      // Without the leading loading state a refresh would leave the previous result on
      // screen with no sign that anything is happening.
      expect(states.first.isLoading, isTrue);
    });
  });
}
