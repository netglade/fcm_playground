import 'package:fcm_app/domains/runs/entities/run_scheduler_exception.dart';
import 'package:fcm_app/pages/runs/runs_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_run_scheduler.dart';
import '../../helpers/pump_app.dart';

void main() {
  RunSummary summary(String id, Map<RunItemState, int> states) => RunSummary(
    runId: id,
    createdAt: DateTime.utc(2026, 8, 17, 9, 0),
    itemCount: states.values.fold(0, (sum, n) => sum + n),
    states: states,
    nextDueAt: states.containsKey(RunItemState.pending)
        ? DateTime.utc(2026, 8, 17, 9, 0, 30)
        : null,
  );

  Future<void> pump(WidgetTester tester, FakeRunScheduler scheduler) => pumpApp(
    tester,
    // Nothing here taps a run, so the sink only needs somewhere to go.
    RunsView(scheduler: scheduler, onRunSelected: <String>[].add),
  );

  testWidgets('says so plainly when nothing has been scheduled', (
    tester,
  ) async {
    await pump(tester, FakeRunScheduler());
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing scheduled yet'), findsOneWidget);
  });

  testWidgets('lists a run with its size and its tally', (tester) async {
    await pump(
      tester,
      FakeRunScheduler(
        summaries: [
          summary('run-1', {RunItemState.sent: 2, RunItemState.pending: 1}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3 sends'), findsOneWidget);
    expect(find.textContaining('2 sent'), findsOneWidget);
    expect(find.textContaining('1 pending'), findsOneWidget);
  });

  testWidgets('reads a real singular for a one-item run', (tester) async {
    await pump(
      tester,
      FakeRunScheduler(
        summaries: [
          summary('run-1', {RunItemState.sent: 1}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('1 send'),
      findsOneWidget,
      reason:
          'a one-item run used to read "1 sends"; this is the whole point of '
          'making the count a real plural',
    );
    expect(
      find.textContaining('1 sends'),
      findsNothing,
      reason:
          'find.text alone would not catch a regression that reintroduced the '
          'plural form, because "1 send" is a prefix of "1 sends"',
    );
  });

  testWidgets('hands the tapped run id to its caller', (tester) async {
    final tapped = <String>[];
    await pumpApp(
      tester,
      RunsView(
        scheduler: FakeRunScheduler(
          summaries: [
            summary('run-1', {RunItemState.sent: 1}),
          ],
        ),
        onRunSelected: tapped.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-run-1')));

    expect(tapped, ['run-1']);
  });

  testWidgets('shows the reason when the API cannot be reached', (
    tester,
  ) async {
    await pump(
      tester,
      FakeRunScheduler(
        failure: const RunSchedulerException('adb reverse tcp:8080'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('adb reverse'), findsOneWidget);
  });
}
