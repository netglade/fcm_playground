import 'package:fcm_app/domains/telemetry/telemetry_reader_exception.dart';
import 'package:fcm_app/pages/telemetry/telemetry_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_telemetry_reader.dart';
import '../../helpers/pump_app.dart';

void main() {
  TelemetryEvent event(
    String traceId,
    TelemetryEventType type, {
    String? detail,
  }) => TelemetryEvent(
    traceId: traceId,
    type: type,
    at: DateTime.utc(2026, 8, 18, 9, 30),
    deviceId: 'd1',
    scenarioId: 'a1_notification_only',
    detail: detail,
  );

  Future<void> pumpPage(WidgetTester tester, FakeTelemetryReader reader) async {
    await pumpApp(tester, TelemetryView(reader: reader));
    await tester.pumpAndSettle();
  }

  testWidgets('offers both tabs', (tester) async {
    await pumpPage(tester, FakeTelemetryReader());

    // The page is the one surface for both questions the pipeline answers, so neither
    // tab may be reachable only by knowing it is there.
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Latency'), findsOneWidget);
  });

  testWidgets('lists a trace with the events that arrived', (tester) async {
    await pumpPage(
      tester,
      FakeTelemetryReader(
        events: [
          event('t1', TelemetryEventType.queued),
          event('t1', TelemetryEventType.opened, detail: 'background'),
        ],
      ),
    );

    expect(find.textContaining('t1'), findsWidgets);
    expect(find.text('queued'), findsOneWidget);
    // The detail, because "which state" is the whole point of the opened row.
    expect(find.textContaining('background'), findsWidgets);
  });

  testWidgets('says which of the ten did not arrive', (tester) async {
    await pumpPage(
      tester,
      FakeTelemetryReader(events: [event('t1', TelemetryEventType.queued)]),
    );

    // All ten are drawn whether or not they happened: a card that listed only what
    // arrived could not answer "did this push get displayed?".
    for (final type in TelemetryEventType.values) {
      expect(find.text(type.wireName), findsOneWidget);
    }
  });

  testWidgets('marks sent and send_failed as the pre-request stamp', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeTelemetryReader(
        events: [
          event('t1', TelemetryEventType.sent, detail: 'msg-1'),
          event('t2', TelemetryEventType.sendFailed, detail: 'UNREGISTERED'),
        ],
      ),
    );

    // Both are stamped from the one clock reading taken before the API calls FCM,
    // so both need the same caveat — a bare time on either would read as a
    // response time neither is.
    expect(find.textContaining('(request received)'), findsNWidgets(2));
  });

  testWidgets('shows the reader failure instead of an empty page', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeTelemetryReader(
        failure: const TelemetryReaderException('the API is not running'),
      ),
    );

    expect(find.text('the API is not running'), findsOneWidget);
  });

  testWidgets('draws a latency cell for a paired row', (tester) async {
    await pumpPage(
      tester,
      FakeTelemetryReader(
        rows: [
          LatencyRow(
            traceId: 't1',
            deviceId: 'd1',
            sentAt: DateTime.utc(2026, 8, 18, 9, 30),
            receivedAt: DateTime.utc(2026, 8, 18, 9, 30, 0, 300),
            scenarioId: 'a1_notification_only',
          ),
        ],
      ),
    );
    await tester.tap(find.text('Latency'));
    await tester.pumpAndSettle();

    expect(find.textContaining('300'), findsWidgets);
    // Every figure on this tab derives from `sent`, so the tab itself must say what
    // event_row.dart says only on the Events tab: that the figure is inflated by
    // the FCM call.
    expect(
      find.textContaining('is when the API received the request'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the newest of several measurements for one cell, with a count',
    (tester) async {
      await pumpPage(
        tester,
        FakeTelemetryReader(
          rows: [
            LatencyRow(
              traceId: 't1',
              deviceId: 'd1',
              sentAt: DateTime.utc(2026, 8, 18, 9, 0),
              receivedAt: DateTime.utc(2026, 8, 18, 9, 0, 0, 500),
              scenarioId: 'a1_notification_only',
            ),
            LatencyRow(
              traceId: 't2',
              deviceId: 'd1',
              sentAt: DateTime.utc(2026, 8, 18, 9, 30),
              receivedAt: DateTime.utc(2026, 8, 18, 9, 30, 0, 300),
              scenarioId: 'a1_notification_only',
            ),
          ],
        ),
      );
      await tester.tap(find.text('Latency'));
      await tester.pumpAndSettle();

      // The later-sent row wins the cell, not the oldest one merely scanned first,
      // and the count says two measurements landed here.
      expect(find.text('300 ms (n=2)'), findsOneWidget);
      expect(find.textContaining('500 ms'), findsNothing);
    },
  );
}
