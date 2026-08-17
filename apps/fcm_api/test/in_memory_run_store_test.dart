import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 17, 9, 0);

  SendMessageRequest request() => SendMessageRequest(
    target: const TokenTarget('device-token'),
    message: FcmMessage.fromJson(const {
      'data': {'event': 'killed_probe'},
    }),
  );

  ScheduledRun runOf(String id, List<int> dueInSeconds) => ScheduledRun(
    id: id,
    createdAt: createdAt,
    items: [
      for (final (index, seconds) in dueInSeconds.indexed)
        ScheduledRunItem(
          index: index,
          request: request(),
          dueAt: createdAt.add(Duration(seconds: seconds)),
        ),
    ],
  );

  late InMemoryRunStore store;

  setUp(() => store = InMemoryRunStore());

  test('finds a saved run, and answers null for one it never saw', () async {
    await store.save(runOf('run-1', [30]));

    expect((await store.find('run-1'))?.items, hasLength(1));
    expect(await store.find('run-2'), isNull);
  });

  test('lists the newest runs first, capped at the limit asked for', () async {
    await store.save(runOf('older', [30]));
    await store.save(
      ScheduledRun(
        id: 'newer',
        createdAt: createdAt.add(const Duration(minutes: 1)),
        items: runOf('newer', [30]).items,
      ),
    );

    expect((await store.recent(limit: 5)).map((r) => r.id), ['newer', 'older']);
    expect(await store.recent(limit: 1), hasLength(1));
  });

  test('recent breaks a createdAt tie by descending id', () async {
    await store.save(runOf('run-a', [30]));
    await store.save(runOf('run-b', [30]));

    expect((await store.recent()).map((r) => r.id), ['run-b', 'run-a']);
  });

  test(
    'claims every item due now, and leaves the ones still to come',
    () async {
      await store.save(runOf('run-1', [30, 60]));

      final claimed = await store.claimDue(
        createdAt.add(const Duration(seconds: 30)),
      );

      expect(claimed.map((c) => c.$2.index), [0]);
      expect(claimed.single.$1, 'run-1');
      expect(claimed.single.$2.state, RunItemState.dispatching);
    },
  );

  test(
    'claimDue returns items in due order across runs, not save order',
    () async {
      await store.save(runOf('later-saved-first', [60]));
      await store.save(runOf('sooner-saved-second', [30]));

      final claimed = await store.claimDue(
        createdAt.add(const Duration(seconds: 60)),
      );

      expect(claimed.map((c) => c.$1), [
        'sooner-saved-second',
        'later-saved-first',
      ]);
    },
  );

  test(
    'claiming persists the claim, so a second claim finds nothing',
    () async {
      await store.save(runOf('run-1', [30]));
      final at = createdAt.add(const Duration(seconds: 30));

      await store.claimDue(at);

      expect(await store.claimDue(at), isEmpty);
      expect(
        (await store.find('run-1'))!.items.single.state,
        RunItemState.dispatching,
      );
    },
  );

  test('cancels only pending items, never a claimed one', () async {
    await store.save(runOf('run-1', [30, 60]));
    await store.claimDue(createdAt.add(const Duration(seconds: 30)));

    expect(await store.cancelPending('run-1'), 1);
    expect((await store.find('run-1'))!.items.map((i) => i.state), [
      RunItemState.dispatching,
      RunItemState.cancelled,
    ]);
  });

  test('answers null when cancelling a run that does not exist', () async {
    expect(await store.cancelPending('nope'), isNull);
  });

  test(
    'reports zero rather than failing when nothing is left to cancel',
    () async {
      await store.save(runOf('run-1', [30]));
      await store.cancelPending('run-1');

      expect(await store.cancelPending('run-1'), 0);
    },
  );

  test('updateItem replaces one item and leaves its neighbours', () async {
    await store.save(runOf('run-1', [30, 60]));
    final run = (await store.find('run-1'))!;

    await store.updateItem(
      'run-1',
      run.items.first.copyWith(state: RunItemState.sent, traceId: 'tr-1'),
    );

    final updated = (await store.find('run-1'))!;
    expect(updated.items.first.traceId, 'tr-1');
    expect(updated.items.last.state, RunItemState.pending);
  });

  test('unfinished holds runs with outstanding items only', () async {
    await store.save(runOf('open', [30]));
    await store.save(runOf('closed', [30]));
    await store.cancelPending('closed');

    expect((await store.unfinished()).map((r) => r.id), ['open']);
  });
}
