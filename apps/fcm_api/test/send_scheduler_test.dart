import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'blocking_fcm_sender.dart';
import 'fake_fcm_sender.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 17, 9, 0);

  Map<String, Object?> itemJson({String scenarioId = 'b3_killed'}) => {
    'token': 'device-token',
    'scenario_id': scenarioId,
    'message': {
      'data': {'event': 'killed_probe'},
    },
  };

  ScheduleRunRequest requestWith({
    int delay = 30,
    int spacing = 0,
    int count = 1,
  }) => ScheduleRunRequest.fromJson({
    'delay_seconds': delay,
    'spacing_seconds': spacing,
    'items': [for (var i = 0; i < count; i++) itemJson(scenarioId: 'b$i')],
  });

  late InMemoryRunStore runs;
  late InMemoryTelemetryStore telemetry;
  late FakeFcmSender sender;
  late int minted;

  SendScheduler schedulerWith(FcmSender fcm) => SendScheduler(
    runs: runs,
    telemetry: telemetry,
    sender: fcm,
    newId: () => 'id-${++minted}',
  );

  setUp(() {
    runs = InMemoryRunStore();
    telemetry = InMemoryTelemetryStore();
    sender = FakeFcmSender();
    minted = 0;
  });

  group('schedule', () {
    test('spaces the items out from the delay', () async {
      final run = await schedulerWith(
        sender,
      ).schedule(requestWith(delay: 30, spacing: 5, count: 3), createdAt);

      expect(run.items.map((i) => i.dueAt), [
        createdAt.add(const Duration(seconds: 30)),
        createdAt.add(const Duration(seconds: 35)),
        createdAt.add(const Duration(seconds: 40)),
      ]);
      expect(run.items.every((i) => i.state == RunItemState.pending), isTrue);
    });

    test('stores the run, so it survives the process that made it', () async {
      final run = await schedulerWith(
        sender,
      ).schedule(requestWith(), createdAt);

      expect((await runs.find(run.id))?.items, hasLength(1));
    });
  });

  group('tick', () {
    test('sends nothing before the item is due', () async {
      final scheduler = schedulerWith(sender);
      await scheduler.schedule(requestWith(delay: 30), createdAt);

      await scheduler.tick(createdAt.add(const Duration(seconds: 29)));

      expect(sender.sent, isEmpty);
    });

    test('sends a due item and records the outcome on it', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 30), createdAt);
      final at = createdAt.add(const Duration(seconds: 30));

      await scheduler.tick(at);

      final item = (await runs.find(run.id))!.items.single;
      expect(item.state, RunItemState.sent);
      expect(item.messageId, 'projects/p/messages/0:17');
      expect(item.dispatchedAt, at);
      expect(item.traceId, isNotNull);
    });

    test('sends through the same path an immediate send takes', () async {
      final scheduler = schedulerWith(sender);
      await scheduler.schedule(requestWith(delay: 0), createdAt);

      await scheduler.tick(createdAt);

      final message = sender.sent.single['message']! as Map<String, Object?>;
      final data = message['data']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
      expect(data['scenario_id'], 'b0');
      expect(data['trace_id'], isNotNull);
    });

    test('records queued and sent against the item\'s own trace', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 0), createdAt);

      await scheduler.tick(createdAt);

      final traceId = (await runs.find(run.id))!.items.single.traceId!;
      expect((await telemetry.eventsForTraces([traceId])).map((e) => e.type), [
        TelemetryEventType.queued,
        TelemetryEventType.sent,
      ]);
    });

    test('does not send the same item twice', () async {
      final scheduler = schedulerWith(sender);
      await scheduler.schedule(requestWith(delay: 0), createdAt);

      await scheduler.tick(createdAt);
      await scheduler.tick(createdAt.add(const Duration(seconds: 1)));

      expect(sender.sent, hasLength(1));
    });

    test('marks a refused item failed and keeps the reason', () async {
      final failing = FakeFcmSender(
        failure: const FcmSendException(
          status: 'UNREGISTERED',
          message: 'gone',
        ),
      );
      final scheduler = schedulerWith(failing);
      final run = await scheduler.schedule(requestWith(delay: 0), createdAt);

      await scheduler.tick(createdAt);

      final item = (await runs.find(run.id))!.items.single;
      expect(item.state, RunItemState.failed);
      expect(item.error, contains('no longer valid'));
    });

    test('a failure does not stop the rest of the batch', () async {
      final failing = FakeFcmSender(
        failure: const FcmSendException(
          status: 'UNREGISTERED',
          message: 'gone',
        ),
      );
      final scheduler = schedulerWith(failing);
      final run = await scheduler.schedule(
        requestWith(delay: 0, count: 3),
        createdAt,
      );

      await scheduler.tick(createdAt);

      expect(
        (await runs.find(run.id))!.items.map((i) => i.state),
        List.filled(3, RunItemState.failed),
      );
      expect(failing.sent, hasLength(3));
    });

    test('a tick starting while one is in flight does nothing', () async {
      final blocking = BlockingFcmSender();
      final scheduler = schedulerWith(blocking);
      final run = await scheduler.schedule(
        requestWith(delay: 0, spacing: 1, count: 2),
        createdAt,
      );

      final firstTick = scheduler.tick(createdAt);
      while (blocking.sent.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      // The second item is due by now, and the first send is still parked
      // inside FCM — this is what a guardless `tick` would claim and dispatch.
      await scheduler.tick(createdAt.add(const Duration(seconds: 1)));

      blocking.gate.complete();
      await firstTick;

      expect(blocking.sent, hasLength(1));
      expect((await runs.find(run.id))!.items[1].state, RunItemState.pending);
    });

    test(
      'clears the guard even when a send throws something unexpected',
      () async {
        final blocking = BlockingFcmSender()..failure = StateError('boom');
        final scheduler = schedulerWith(blocking);
        await scheduler.schedule(requestWith(delay: 0), createdAt);

        final firstTick = scheduler.tick(createdAt);
        while (blocking.sent.isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        blocking.gate.complete();

        await expectLater(firstTick, throwsStateError);

        // If `_ticking` were left latched shut by the throw, this tick would do
        // nothing and `sent` would stay at 1.
        blocking.failure = null;
        await scheduler.schedule(requestWith(delay: 0), createdAt);
        await scheduler.tick(createdAt);

        expect(blocking.sent, hasLength(2));
      },
    );
  });

  group('reading runs back', () {
    test('finds a run by id and answers null for an unknown one', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(), createdAt);

      expect((await scheduler.find(run.id))?.id, run.id);
      expect(await scheduler.find('nope'), isNull);
    });

    test('summarises the recent runs newest first', () async {
      final scheduler = schedulerWith(sender);
      await scheduler.schedule(requestWith(count: 2), createdAt);
      await scheduler.schedule(
        requestWith(),
        createdAt.add(const Duration(minutes: 1)),
      );

      final summaries = await scheduler.recent();

      expect(summaries.first.itemCount, 1);
      expect(summaries.last.itemCount, 2);
      expect(summaries.last.count(RunItemState.pending), 2);
    });
  });

  group('cancel', () {
    test('cancels what is still pending and reports how many', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(
        requestWith(delay: 30, spacing: 30, count: 3),
        createdAt,
      );

      expect(await scheduler.cancel(run.id), 3);
      expect(
        (await runs.find(run.id))!.items.map((i) => i.state),
        List.filled(3, RunItemState.cancelled),
      );
    });

    test('leaves an already-sent item alone', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(
        requestWith(delay: 0, spacing: 60, count: 2),
        createdAt,
      );
      await scheduler.tick(createdAt);

      expect(await scheduler.cancel(run.id), 1);
      expect((await runs.find(run.id))!.items.map((i) => i.state), [
        RunItemState.sent,
        RunItemState.cancelled,
      ]);
    });

    test('answers null for a run that does not exist', () async {
      expect(await schedulerWith(sender).cancel('nope'), isNull);
    });

    test('a cancelled item is never sent afterwards', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 30), createdAt);

      await scheduler.cancel(run.id);
      await scheduler.tick(createdAt.add(const Duration(seconds: 60)));

      expect(sender.sent, isEmpty);
    });
  });

  group('recover', () {
    test('sends an item that came due while the server was down', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 30), createdAt);

      await scheduler.recover(createdAt.add(const Duration(seconds: 90)));

      expect((await runs.find(run.id))!.items.single.state, RunItemState.sent);
    });

    test('misses one overdue by more than the grace period', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 30), createdAt);

      await scheduler.recover(createdAt.add(const Duration(minutes: 30)));

      expect(
        (await runs.find(run.id))!.items.single.state,
        RunItemState.missed,
      );
      expect(sender.sent, isEmpty);
    });

    test('leaves an item still in the future for the ticker', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 300), createdAt);

      await scheduler.recover(createdAt.add(const Duration(seconds: 10)));

      expect(
        (await runs.find(run.id))!.items.single.state,
        RunItemState.pending,
      );
    });

    test('resolves an interrupted dispatch that FCM had accepted', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 0), createdAt);
      // The state a process killed between `queued` and the outcome leaves behind.
      await runs.updateItem(
        run.id,
        run.items.single.copyWith(
          state: RunItemState.dispatching,
          traceId: 'tr-interrupted',
        ),
      );
      await telemetry.record([
        TelemetryEvent(
          traceId: 'tr-interrupted',
          type: TelemetryEventType.sent,
          at: createdAt,
          deviceId: '',
          detail: 'projects/p/messages/0:99',
        ),
      ]);

      await scheduler.recover(createdAt.add(const Duration(seconds: 5)));

      final item = (await runs.find(run.id))!.items.single;
      expect(item.state, RunItemState.sent);
      expect(item.messageId, 'projects/p/messages/0:99');
      // Read back rather than resent: the message already left.
      expect(sender.sent, isEmpty);
    });

    test('fails an interrupted dispatch FCM never answered', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 0), createdAt);
      await runs.updateItem(
        run.id,
        run.items.single.copyWith(
          state: RunItemState.dispatching,
          traceId: 'tr-interrupted',
        ),
      );
      await telemetry.record([
        TelemetryEvent(
          traceId: 'tr-interrupted',
          type: TelemetryEventType.queued,
          at: createdAt,
          deviceId: '',
        ),
      ]);

      await scheduler.recover(createdAt.add(const Duration(seconds: 5)));

      final item = (await runs.find(run.id))!.items.single;
      expect(item.state, RunItemState.failed);
      expect(item.error, contains('stopped'));
    });

    test('carries FCM\'s refusal through from the telemetry', () async {
      final scheduler = schedulerWith(sender);
      final run = await scheduler.schedule(requestWith(delay: 0), createdAt);
      await runs.updateItem(
        run.id,
        run.items.single.copyWith(
          state: RunItemState.dispatching,
          traceId: 'tr-interrupted',
        ),
      );
      await telemetry.record([
        TelemetryEvent(
          traceId: 'tr-interrupted',
          type: TelemetryEventType.sendFailed,
          at: createdAt,
          deviceId: '',
          detail: 'UNREGISTERED',
        ),
      ]);

      await scheduler.recover(createdAt.add(const Duration(seconds: 5)));

      final item = (await runs.find(run.id))!.items.single;
      expect(item.state, RunItemState.failed);
      expect(item.error, contains('UNREGISTERED'));
    });
  });
}
