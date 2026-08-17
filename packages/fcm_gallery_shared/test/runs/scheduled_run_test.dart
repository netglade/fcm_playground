import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 17, 9, 0);

  SendMessageRequest requestFor(String scenarioId) => SendMessageRequest(
    target: const TokenTarget('device-token'),
    message: FcmMessage.fromJson(const {
      'data': {'event': 'killed_probe'},
    }),
    scenarioId: scenarioId,
  );

  ScheduledRun runOf(int count) => ScheduledRun(
    id: 'run-1',
    createdAt: createdAt,
    items: [
      for (var i = 0; i < count; i++)
        ScheduledRunItem(
          index: i,
          request: requestFor('b$i'),
          dueAt: createdAt.add(Duration(seconds: 30 + i * 5)),
        ),
    ],
  );

  group('ScheduledRun', () {
    test('round-trips through JSON', () {
      final restored = ScheduledRun.fromJson(runOf(2).toJson());

      expect(restored.id, 'run-1');
      expect(restored.createdAt, createdAt);
      expect(restored.items.map((i) => i.index), [0, 1]);
      expect(restored.items.last.request.scenarioId, 'b1');
    });

    test('withItem replaces the item at that index and leaves the rest', () {
      final run = runOf(3);

      final updated = run.withItem(
        run.items[1].copyWith(state: RunItemState.sent, traceId: 'tr-2'),
      );

      expect(updated.items.map((i) => i.state), [
        RunItemState.pending,
        RunItemState.sent,
        RunItemState.pending,
      ]);
      expect(updated.items[1].traceId, 'tr-2');
    });
  });

  group('RunSummary', () {
    test('tallies the states and names the next item still to come', () {
      final run = runOf(3);
      final summary = RunSummary.of(
        run.withItem(run.items.first.copyWith(state: RunItemState.sent)),
      );

      expect(summary.runId, 'run-1');
      expect(summary.itemCount, 3);
      expect(summary.states[RunItemState.sent], 1);
      expect(summary.states[RunItemState.pending], 2);
      expect(summary.nextDueAt, createdAt.add(const Duration(seconds: 35)));
    });

    test('has no next due time once nothing is outstanding', () {
      var run = runOf(2);
      for (final item in run.items) {
        run = run.withItem(item.copyWith(state: RunItemState.cancelled));
      }

      expect(RunSummary.of(run).nextDueAt, isNull);
    });

    test('round-trips through JSON', () {
      final restored = RunSummary.fromJson(RunSummary.of(runOf(2)).toJson());

      expect(restored.itemCount, 2);
      expect(restored.states[RunItemState.pending], 2);
      expect(restored.nextDueAt, createdAt.add(const Duration(seconds: 30)));
    });
  });
}
