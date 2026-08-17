import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  final dueAt = DateTime.utc(2026, 8, 17, 9, 0, 30);

  ScheduledRunItem itemAt(DateTime due) => ScheduledRunItem(
    index: 0,
    request: SendMessageRequest(
      target: const TokenTarget('device-token'),
      message: FcmMessage.fromJson(const {
        'data': {'event': 'killed_probe'},
      }),
      scenarioId: 'b3_killed',
    ),
    dueAt: due,
  );

  group('RunItemState', () {
    test('every state has the wire name the database and the app agree on', () {
      expect(RunItemState.values.map((s) => s.wireName), [
        'pending',
        'dispatching',
        'sent',
        'failed',
        'cancelled',
        'missed',
      ]);
    });

    test('refuses an unknown wire name rather than guessing', () {
      expect(
        () => RunItemState.fromWireName('done'),
        throwsA(isA<FormatException>()),
      );
    });

    test('is outstanding only while pending or dispatching', () {
      expect(RunItemState.pending.isOutstanding, isTrue);
      expect(RunItemState.dispatching.isOutstanding, isTrue);
      expect(RunItemState.sent.isOutstanding, isFalse);
      expect(RunItemState.failed.isOutstanding, isFalse);
      expect(RunItemState.cancelled.isOutstanding, isFalse);
      expect(RunItemState.missed.isOutstanding, isFalse);
    });
  });

  group('ScheduledRunItem', () {
    test('starts pending with no outcome', () {
      final item = itemAt(dueAt);

      expect(item.state, RunItemState.pending);
      expect(item.traceId, isNull);
      expect(item.events, isEmpty);
    });

    test('normalises dueAt to UTC, so a local time cannot fire hours late', () {
      final item = itemAt(DateTime(2026, 8, 17, 9, 0, 30));

      expect(item.dueAt.isUtc, isTrue);
    });

    test('round-trips through JSON with its outcome and its timeline', () {
      final original = itemAt(dueAt).copyWith(
        state: RunItemState.sent,
        traceId: 'tr-1',
        messageId: 'projects/p/messages/0:17',
        dispatchedAt: dueAt,
        events: [
          TelemetryEvent(
            traceId: 'tr-1',
            type: TelemetryEventType.sent,
            at: dueAt,
            deviceId: '',
          ),
        ],
      );

      final restored = ScheduledRunItem.fromJson(original.toJson());

      expect(restored.state, RunItemState.sent);
      expect(restored.traceId, 'tr-1');
      expect(restored.messageId, 'projects/p/messages/0:17');
      expect(restored.dueAt, dueAt);
      expect(restored.dispatchedAt, dueAt);
      expect(restored.request.scenarioId, 'b3_killed');
      expect(restored.events.single.type, TelemetryEventType.sent);
    });

    test('omits an empty timeline, which is what the store persists', () {
      expect(itemAt(dueAt).toJson(), isNot(contains('events')));
    });
  });
}
