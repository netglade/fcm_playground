import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'sqlite_availability.dart';

void main() {
  // Probed once, at registration time, so every test in the group carries the
  // same verdict.
  final skipReason = sqliteAvailability();

  // Hoisted out of the `group` call so it fits on one line: `dart format` and
  // `prefer-trailing-comma` cannot both be satisfied while the body is written
  // inline, as `sqlite_telemetry_store_test.dart` does for the same reason.
  group('SqliteRunStore', _storeBehaviour, skip: skipReason);
}

void _storeBehaviour() {
  final createdAt = DateTime.utc(2026, 8, 17, 9, 0);

  ScheduledRun runOf(String id, List<int> dueInSeconds, {DateTime? at}) =>
      ScheduledRun(
        id: id,
        createdAt: at ?? createdAt,
        items: [
          for (final (index, seconds) in dueInSeconds.indexed)
            ScheduledRunItem(
              index: index,
              request: SendMessageRequest(
                target: const TokenTarget('device-token'),
                message: FcmMessage.fromJson(const {
                  'data': {'event': 'killed_probe'},
                }),
                scenarioId: 'b3_killed',
              ),
              dueAt: (at ?? createdAt).add(Duration(seconds: seconds)),
            ),
        ],
      );

  late Directory directory;
  late SqliteRunStore store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fcm-runs');
    store = SqliteRunStore.open('${directory.path}/runs.sqlite');
  });

  tearDown(() async {
    await store.close();
    directory.deleteSync(recursive: true);
  });

  test('reads back a saved run whole, request included', () async {
    await store.save(runOf('run-1', [30, 60]));

    final run = (await store.find('run-1'))!;
    expect(run.createdAt, createdAt);
    expect(run.items, hasLength(2));
    expect(run.items.first.request.scenarioId, 'b3_killed');
    expect(run.items.last.dueAt, createdAt.add(const Duration(seconds: 60)));
  });

  test('skips a row it cannot parse rather than losing the whole run', () async {
    await store.save(runOf('run-1', [30, 60]));

    // A second connection to the same file, standing in for a hand-edited or
    // partially-migrated row `ScheduledRunItem.fromJson` cannot make sense of.
    final raw = sqlite3.open('${directory.path}/runs.sqlite');
    raw.execute('UPDATE run_items SET item = ? WHERE run_id = ? AND idx = 0', [
      'not json at all',
      'run-1',
    ]);
    raw.dispose();

    final run = (await store.find('run-1'))!;

    expect(run.items, hasLength(1));
    expect(run.items.single.dueAt, createdAt.add(const Duration(seconds: 60)));
  });

  test(
    'survives being closed and reopened, which is the whole point',
    () async {
      final path = '${directory.path}/runs.sqlite';
      await store.save(runOf('run-1', [30]));
      await store.close();

      store = SqliteRunStore.open(path);

      expect((await store.find('run-1'))?.items, hasLength(1));
    },
  );

  test('lists the newest runs first, capped at the limit', () async {
    await store.save(runOf('older', [30]));
    await store.save(
      runOf('newer', [30], at: createdAt.add(const Duration(minutes: 1))),
    );

    expect((await store.recent(limit: 5)).map((r) => r.id), ['newer', 'older']);
    expect(await store.recent(limit: 1), hasLength(1));
  });

  test('recent breaks a createdAt tie by descending id', () async {
    await store.save(runOf('run-a', [30]));
    await store.save(runOf('run-b', [30]));

    expect((await store.recent()).map((r) => r.id), ['run-b', 'run-a']);
  });

  test('claims due items once and persists the claim', () async {
    await store.save(runOf('run-1', [30, 60]));
    final at = createdAt.add(const Duration(seconds: 30));

    final claimed = await store.claimDue(at);

    expect(claimed.map((c) => c.$2.index), [0]);
    expect(claimed.single.$2.state, RunItemState.dispatching);
    expect(await store.claimDue(at), isEmpty);
  });

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

  test('cancels only pending items and reports the count', () async {
    await store.save(runOf('run-1', [30, 60]));
    await store.claimDue(createdAt.add(const Duration(seconds: 30)));

    expect(await store.cancelPending('run-1'), 1);
    expect(await store.cancelPending('nope'), isNull);
  });

  test('updateItem replaces one item and keeps its neighbour', () async {
    await store.save(runOf('run-1', [30, 60]));
    final run = (await store.find('run-1'))!;

    await store.updateItem(
      'run-1',
      run.items.first.copyWith(
        state: RunItemState.sent,
        traceId: 'tr-1',
        messageId: 'projects/p/messages/0:17',
      ),
    );

    final updated = (await store.find('run-1'))!;
    expect(updated.items.first.messageId, 'projects/p/messages/0:17');
    expect(updated.items.last.state, RunItemState.pending);
  });

  test('unfinished holds runs with outstanding items only', () async {
    await store.save(runOf('open', [30]));
    await store.save(runOf('closed', [30]));
    await store.cancelPending('closed');

    expect((await store.unfinished()).map((r) => r.id), ['open']);
  });
}
