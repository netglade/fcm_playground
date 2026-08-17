import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/pages/countdown/countdown_page.dart';
import 'package:fcm_app/pages/runs/run_timeline_page.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../fakes/fake_notification_sender.dart';
import '../../../fakes/fake_run_scheduler.dart';
import '../../../fakes/in_memory_active_run_store.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late FakeRunScheduler runs;
  late SandboxCubit controller;

  void build() {
    runs = FakeRunScheduler();
    controller = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => 'device-token',
      startRun: StartRun(scheduler: runs, active: InMemoryActiveRunStore()),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<RunScheduler>.value(
          value: runs,
          child: Scaffold(
            body: BlocProvider.value(
              value: controller,
              child: const SendFooter(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => controller.close());

  testWidgets(
    'opens the countdown once a delay is chosen, and schedules exactly one run',
    (tester) async {
      build();
      await pump(tester);

      await tester.tap(find.text('Schedule…'));
      await tester.pumpAndSettle();

      // The sheet is up, offering the confirm button `schedule_sheet_test.dart`
      // already pins the behaviour of.
      expect(find.text('Schedule'), findsOneWidget);

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.byType(CountdownPage), findsOneWidget);
      expect(runs.scheduled, hasLength(1));
    },
  );

  testWidgets('hands off to the timeline once the countdown finishes', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.text('Schedule…'));
    await tester.pumpAndSettle();
    // The default scenario names no delay of its own, so the sheet opens on
    // the 30 s fallback — the shortest preset has to be picked explicitly to
    // keep this test's virtual wait short.
    await tester.tap(find.text('10 s'));
    await tester.pump();
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.byType(CountdownPage), findsOneWidget);

    // `testWidgets` runs inside a `FakeAsync` zone, so this advances the
    // countdown's real one-second `Stream.periodic` through all ten ticks
    // without any wall-clock wait and without the footer exposing a tick
    // stream of its own.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    // `pushReplacement`, not `push`: the countdown is gone, not merely
    // covered, once the hand-off happens.
    expect(find.byType(RunTimelinePage), findsOneWidget);
    expect(find.byType(CountdownPage), findsNothing);
  });

  testWidgets('does not schedule anything when the sheet is dismissed', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.text('Schedule…'));
    await tester.pumpAndSettle();

    // Dismiss by tapping the scrim rather than confirming.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(CountdownPage), findsNothing);
    expect(runs.scheduled, isEmpty);
  });

  testWidgets('is withheld exactly when Send is', (tester) async {
    build();
    controller.form.android.ttl.updateValue('not a duration');
    await pump(tester);

    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });
}
