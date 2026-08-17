import 'package:fcm_app/telemetry/report_push_event.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_push_telemetry.dart';
import 'throwing_push_telemetry.dart';

/// A received push as the pipeline sees it: the flat map `remoteMessageToPayload`
/// builds, with `data` spread over it — which is where the send API's injected
/// keys end up.
Map<String, Object?> arrival({String? traceId = 'tr-1', String? scenarioId}) =>
    {
      'id': 'msg-1',
      'title': 'Hello',
      'body': 'A message body.',
      'sentAt': '2026-08-13T09:30:00Z',
      'trace_id': ?traceId,
      'scenario_id': ?scenarioId,
    };

void main() {
  late RecordingPushTelemetry telemetry;

  setUp(() {
    telemetry = RecordingPushTelemetry();
  });

  group('reportAndFlush', () {
    test('records the event and then sends it', () async {
      await reportAndFlush(
        telemetry,
        TelemetryEventType.receivedFg,
        arrival(scenarioId: 'a1_notification_only'),
      );

      expect(telemetry.recorded.single.type, TelemetryEventType.receivedFg);
      expect(telemetry.recorded.single.traceId, 'tr-1');
      expect(telemetry.recorded.single.scenarioId, 'a1_notification_only');
      expect(
        telemetry.recordedAtFlush,
        [1],
        reason:
            'one flush, and it happened after the event was recorded rather '
            'than before it, when it would have carried nothing',
      );
    });

    test('leaves an absent scenario absent rather than empty', () async {
      // A push composed by hand belongs to no scenario, and `''` is a different
      // answer to "which scenario produced this?" than "not from the gallery".
      await reportAndFlush(telemetry, TelemetryEventType.opened, arrival());

      expect(telemetry.recorded.single.scenarioId, isNull);
      expect(telemetry.recorded.single.detail, isNull);
    });

    test('records nothing, and does not flush, without a trace id', () async {
      // A `curl` send by hand carries none. Inventing one would put a message
      // nobody sent into the matrix, which is worse than a gap.
      await reportAndFlush(
        telemetry,
        TelemetryEventType.receivedFg,
        arrival(traceId: null),
      );

      expect(telemetry.recorded, isEmpty);
      expect(
        telemetry.recordedAtFlush,
        isEmpty,
        reason: 'a flush with nothing to send is a request that can only fail',
      );

      await reportAndFlush(telemetry, TelemetryEventType.receivedFg, arrival());

      expect(
        telemetry.recorded.map((event) => event.traceId),
        ['tr-1'],
        reason:
            'the silence above is about the missing id, not about a function '
            'that records nothing for any push',
      );
      expect(telemetry.flushes, 1);
    });

    test('records nothing for a blank or wrong-typed trace id', () async {
      // FCM data values are strings on the wire, but the plugin surfaces them as
      // `Object?`, and a blank id correlates to nothing just as an absent one
      // does.
      for (final value in const [' ', '', 7]) {
        await reportAndFlush(telemetry, TelemetryEventType.receivedFg, {
          ...arrival(traceId: null),
          'trace_id': value,
        });
      }

      expect(telemetry.recorded, isEmpty);
      expect(telemetry.flushes, isZero);
    });

    test('ignores a scenario id that is not usable text', () async {
      // The scenario is an axis of the matrix, not a required field: a bad value
      // must cost the axis, not the arrival.
      await reportAndFlush(telemetry, TelemetryEventType.receivedFg, {
        ...arrival(),
        'scenario_id': ' ',
      });

      expect(telemetry.recorded.single.traceId, 'tr-1');
      expect(telemetry.recorded.single.scenarioId, isNull);
    });
  });

  group('reportWithoutFlushing', () {
    test('records the arrival and deliberately does not send it', () async {
      // For the background isolate, which can be killed at any moment: a
      // half-completed request there loses the event it was trying to save,
      // whereas a buffered row is picked up by the next foreground flush.
      await reportWithoutFlushing(
        telemetry,
        TelemetryEventType.receivedBg,
        arrival(scenarioId: 'a2_data_only'),
      );

      expect(telemetry.recorded.single.type, TelemetryEventType.receivedBg);
      expect(
        telemetry.recorded.single.traceId,
        'tr-1',
        reason:
            'the event was recorded, so the zero below is a flush that did not '
            'happen rather than a hook that did nothing at all',
      );
      expect(telemetry.recorded.single.scenarioId, 'a2_data_only');
      expect(telemetry.flushes, isZero);

      await reportAndFlush(telemetry, TelemetryEventType.receivedFg, arrival());

      expect(
        telemetry.flushes,
        1,
        reason:
            'and the counter does move, so the zero above is not a fake that '
            'cannot count',
      );
    });

    test('records nothing without a trace id', () async {
      await reportWithoutFlushing(
        telemetry,
        TelemetryEventType.receivedBg,
        arrival(traceId: null),
      );

      expect(telemetry.recorded, isEmpty);

      await reportWithoutFlushing(
        telemetry,
        TelemetryEventType.receivedBg,
        arrival(),
      );

      expect(
        telemetry.recorded,
        hasLength(1),
        reason: 'the missing id is what suppressed it, not the function',
      );
    });
  });

  group('a failing reporter', () {
    // Every hook is called fire-and-forget from a push handler, so a throw here
    // would surface as an unhandled asynchronous error on the delivery path —
    // telemetry breaking the thing it exists to observe. The reporter's own
    // promise covers `record`; a `flush` that cannot read its database is the
    // half left over, and it is the half these hooks introduced.
    test('does not escape reportAndFlush', () async {
      final failing = ThrowingPushTelemetry();

      await expectLater(
        reportAndFlush(failing, TelemetryEventType.receivedFg, arrival()),
        completes,
      );
      expect(
        failing.attempted,
        [TelemetryEventType.receivedFg],
        reason:
            'a real failure was swallowed, rather than nothing having been '
            'attempted at all',
      );
    });

    test('does not escape a flush that fails after recording', () async {
      final failing = ThrowingPushTelemetry.onFlush();

      await expectLater(
        reportAndFlush(failing, TelemetryEventType.displayed, arrival()),
        completes,
      );
      expect(failing.attempted, [TelemetryEventType.displayed]);
      expect(failing.flushes, 1, reason: 'the flush was reached and it threw');
    });

    test('does not escape reportWithoutFlushing', () async {
      final failing = ThrowingPushTelemetry();

      await expectLater(
        reportWithoutFlushing(
          failing,
          TelemetryEventType.receivedBg,
          arrival(),
        ),
        completes,
      );
      expect(failing.attempted, [TelemetryEventType.receivedBg]);
    });
  });
}
