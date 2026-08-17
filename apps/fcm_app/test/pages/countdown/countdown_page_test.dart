import 'dart:async';

import 'package:fcm_app/pages/countdown/countdown_page.dart';
import 'package:fcm_app/pages/countdown/cubit/countdown_cubit.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_run_scheduler.dart';
import '../../fakes/in_memory_active_run_store.dart';
import '../../fakes/recording_countdown_screen.dart';

void main() {
  late StreamController<void> ticks;
  late FakeRunScheduler scheduler;
  late InMemoryActiveRunStore active;
  late RecordingCountdownScreen screen;
  late int finished;

  ScheduledRun runOf() => ScheduledRun(
    id: 'run-1',
    createdAt: FakeRunScheduler.createdAt,
    items: [
      ScheduledRunItem(
        index: 0,
        request: SendMessageRequest(
          target: const TokenTarget('device-token'),
          message: const FcmMessage(),
        ),
        dueAt: FakeRunScheduler.createdAt.add(const Duration(seconds: 30)),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, {int delaySeconds = 30}) {
    final run = runOf();
    scheduler.runs['run-1'] = run;

    return tester.pumpWidget(
      MaterialApp(
        home: CountdownPage(
          cubit: CountdownCubit(
            scheduler: scheduler,
            run: run,
            active: active,
            delaySeconds: delaySeconds,
            ticks: ticks.stream,
          ),
          onFinished: () => finished++,
          screen: screen,
        ),
      ),
    );
  }

  setUp(() {
    ticks = StreamController<void>.broadcast();
    scheduler = FakeRunScheduler();
    active = InMemoryActiveRunStore();
    screen = RecordingCountdownScreen();
    finished = 0;
  });

  tearDown(() => ticks.close());

  testWidgets('tells the user what to do, and how long they have', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('30'), findsOneWidget);
    expect(
      find.textContaining('Swipe the app away from recents'),
      findsOneWidget,
    );
  });

  testWidgets('holds the screen awake while it counts', (tester) async {
    await pump(tester);

    expect(screen.calls, contains('keepAwake'));
  });

  testWidgets('redraws every second', (tester) async {
    await pump(tester);

    ticks.add(null);
    await tester.pump();

    expect(find.text('29'), findsOneWidget);
  });

  testWidgets('dims on request, and says what that really does', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.textContaining('cannot switch the display off'),
      findsOneWidget,
    );
    await tester.tap(find.text('Dim the screen'));
    await tester.pump();

    expect(screen.calls, contains('dim'));
  });

  testWidgets('opens the battery settings on request', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Battery settings'));
    await tester.pump();

    expect(screen.calls, contains('battery'));
  });

  testWidgets('cancels the run and leaves', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(scheduler.cancelled, ['run-1']);
    expect(find.byType(CountdownPage), findsNothing);
  });

  testWidgets('releases the screen once it is gone', (tester) async {
    await pump(tester);

    // Replacing the tree disposes CountdownPage the same way leaving the route
    // would, without depending on Cancel's own pop.
    await tester.pumpWidget(const SizedBox.shrink());

    expect(screen.calls, contains('release'));
  });

  testWidgets('calls back once when the delay has elapsed', (tester) async {
    await pump(tester, delaySeconds: 1);

    ticks.add(null);
    await tester.pumpAndSettle();

    expect(finished, 1);
  });
}
