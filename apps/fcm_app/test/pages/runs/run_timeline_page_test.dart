import 'package:fcm_app/pages/runs/run_timeline_page.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_run_scheduler.dart';
import '../../helpers/pump_app.dart';

void main() {
  final at = DateTime.utc(2026, 8, 17, 9, 0, 30);

  ScheduledRun runWith(ScheduledRunItem item) => ScheduledRun(
    id: 'run-1',
    createdAt: DateTime.utc(2026, 8, 17, 9, 0),
    items: [item],
  );

  ScheduledRunItem itemWith({
    required RunItemState state,
    List<TelemetryEvent> events = const [],
    String? error,
  }) => ScheduledRunItem(
    index: 0,
    request: SendMessageRequest(
      target: const TokenTarget('device-token'),
      message: const FcmMessage(),
      scenarioId: 'b3_killed',
    ),
    dueAt: at,
    state: state,
    error: error,
    events: events,
  );

  Future<void> pump(WidgetTester tester, ScheduledRun run) async {
    final scheduler = FakeRunScheduler()..runs['run-1'] = run;
    await pumpApp(
      tester,
      RunTimelinePage(scheduler: scheduler, runId: 'run-1'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names the scenario and the state of each item', (tester) async {
    await pump(tester, runWith(itemWith(state: RunItemState.sent)));

    expect(find.text('b3_killed'), findsOneWidget);
    expect(find.text('sent'), findsOneWidget);
  });

  testWidgets('draws the events in the order they were recorded', (
    tester,
  ) async {
    await pump(
      tester,
      runWith(
        itemWith(
          state: RunItemState.sent,
          events: [
            TelemetryEvent(
              traceId: 'tr-1',
              type: TelemetryEventType.queued,
              at: at,
              deviceId: '',
            ),
            TelemetryEvent(
              traceId: 'tr-1',
              type: TelemetryEventType.receivedBg,
              at: at.add(const Duration(seconds: 2)),
              deviceId: 'dev-1',
            ),
          ],
        ),
      ),
    );

    expect(find.text('queued'), findsOneWidget);
    expect(find.text('received_bg'), findsOneWidget);
    // Position, not just presence: reversed or sorted, both would still be
    // found once each.
    expect(
      tester.getTopLeft(find.text('queued')).dy,
      lessThan(tester.getTopLeft(find.text('received_bg')).dy),
    );
  });

  testWidgets('says an item is still waiting rather than showing nothing', (
    tester,
  ) async {
    await pump(tester, runWith(itemWith(state: RunItemState.pending)));

    expect(find.textContaining('Nothing recorded yet'), findsOneWidget);
  });

  testWidgets('shows why a missed item was never sent', (tester) async {
    await pump(
      tester,
      runWith(
        itemWith(
          state: RunItemState.missed,
          error: 'The server was not running when this was due.',
        ),
      ),
    );

    expect(find.text('missed'), findsOneWidget);
    expect(find.textContaining('not running'), findsOneWidget);
  });
}
