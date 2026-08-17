import 'dart:async';

import 'package:fcm_app/domains/runs/entities/run_scheduler_exception.dart';
import 'package:fcm_app/pages/countdown/cubit/countdown_cubit.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_run_scheduler.dart';

void main() {
  late StreamController<void> ticks;
  late FakeRunScheduler scheduler;

  ScheduledRun runOf(String id) => ScheduledRun(
    id: id,
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

  CountdownCubit cubitFor({int delaySeconds = 3, String runId = 'run-1'}) {
    final run = runOf(runId);
    scheduler.runs[runId] = run;

    return CountdownCubit(
      scheduler: scheduler,
      run: run,
      delaySeconds: delaySeconds,
      ticks: ticks.stream,
    );
  }

  Future<void> tick(int times) async {
    for (var i = 0; i < times; i++) {
      ticks.add(null);
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    ticks = StreamController<void>.broadcast();
    scheduler = FakeRunScheduler();
  });

  tearDown(() => ticks.close());

  test('starts at the delay that was asked for', () {
    expect(cubitFor(delaySeconds: 30).state.remainingSeconds, 30);
  });

  test('counts down one second per tick', () async {
    final cubit = cubitFor();

    await tick(2);

    expect(cubit.state.remainingSeconds, 1);
    expect(cubit.state.isFinished, isFalse);
  });

  test('finishes at zero and stops there', () async {
    final cubit = cubitFor();

    await tick(5);

    expect(cubit.state.remainingSeconds, 0);
    expect(cubit.state.isFinished, isTrue);
  });

  test('cancels the run and says so', () async {
    final cubit = cubitFor(delaySeconds: 30);

    await cubit.cancel();

    expect(scheduler.cancelled, ['run-1']);
    expect(cubit.state.isCancelled, isTrue);
  });

  test('a cancelled countdown stops counting', () async {
    final cubit = cubitFor(delaySeconds: 30);

    await cubit.cancel();
    await tick(3);

    expect(cubit.state.remainingSeconds, 30);
  });

  test(
    'reports a cancel the API refused, without cancelling locally',
    () async {
      final failing = FakeRunScheduler(
        failure: const RunSchedulerException('Could not reach the API'),
      );
      final run = runOf('run-1');
      final cubit = CountdownCubit(
        scheduler: failing,
        run: run,
        delaySeconds: 30,
        ticks: ticks.stream,
      );

      await cubit.cancel();

      expect(cubit.state.isCancelled, isFalse);
      expect(cubit.state.error, contains('Could not reach'));
    },
  );
}
