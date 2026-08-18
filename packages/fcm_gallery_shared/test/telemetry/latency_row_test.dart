import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  LatencyRow row({
    DateTime? sentAt,
    DateTime? receivedAt,
    String? scenarioId,
  }) => LatencyRow(
    traceId: 'tr-1',
    deviceId: 'dev-1',
    sentAt: sentAt ?? DateTime.utc(2026, 8, 13, 9, 0, 0),
    receivedAt: receivedAt ?? DateTime.utc(2026, 8, 13, 9, 0, 2),
    scenarioId: scenarioId,
  );

  group('LatencyRow', () {
    test('measures the gap between the send and the arrival', () {
      expect(row().latency, const Duration(seconds: 2));
      expect(row().isSkewed, isFalse);
    });

    test('reports a backwards clock as skew rather than instant delivery', () {
      // Clamping this to zero would turn a measurement error into a false
      // result, and a "1ms on Xiaomi" would discredit every other number here.
      final skewed = row(
        sentAt: DateTime.utc(2026, 8, 13, 9, 0, 5),
        receivedAt: DateTime.utc(2026, 8, 13, 9, 0, 0),
      );

      expect(skewed.isSkewed, isTrue);
      expect(skewed.latency, const Duration(seconds: -5));
    });

    test('normalises both timestamps to UTC, whatever it was given', () {
      // A row serialised from local times writes no `Z`, and the reader then
      // treats it as its own local time — hours of latency out of nowhere.
      final local = row(
        sentAt: DateTime(2026, 8, 13, 9, 0, 0),
        receivedAt: DateTime(2026, 8, 13, 9, 0, 2),
      );

      expect(local.sentAt.isUtc, isTrue);
      expect(local.receivedAt.isUtc, isTrue);
      expect(local.latency, const Duration(seconds: 2));
      expect(local.toJson()['sent_at'], endsWith('Z'));
      expect(local.toJson()['received_at'], endsWith('Z'));
    });

    test('writes snake_case keys, matching the rest of the wire format', () {
      expect(row(scenarioId: 'a1_notification_only').toJson(), {
        'trace_id': 'tr-1',
        'device_id': 'dev-1',
        'sent_at': '2026-08-13T09:00:00.000Z',
        'received_at': '2026-08-13T09:00:02.000Z',
        'scenario_id': 'a1_notification_only',
      });
    });

    test('omits an unknown scenario rather than writing null', () {
      expect(row().toJson().containsKey('scenario_id'), isFalse);
    });

    test('round-trips through the wire format', () {
      final row = LatencyRow(
        traceId: 't1',
        deviceId: 'd1',
        sentAt: DateTime.utc(2026, 8, 18, 9, 30),
        receivedAt: DateTime.utc(2026, 8, 18, 9, 30, 0, 300),
        scenarioId: 'a1_notification_only',
      );

      final decoded = LatencyRow.fromJson(row.toJson());

      // Field by field, because LatencyRow has no `==`: a toJson that dropped a
      // column would otherwise still "round-trip".
      expect(decoded.traceId, row.traceId);
      expect(decoded.deviceId, row.deviceId);
      expect(decoded.sentAt, row.sentAt);
      expect(decoded.receivedAt, row.receivedAt);
      expect(decoded.scenarioId, row.scenarioId);
    });

    test('keeps an absent scenario absent rather than blank', () {
      final row = LatencyRow(
        traceId: 't1',
        deviceId: 'd1',
        sentAt: DateTime.utc(2026, 8, 18, 9, 30),
        receivedAt: DateTime.utc(2026, 8, 18, 9, 31),
        scenarioId: null,
      );

      // `''` and "not from the gallery" are different answers when reading the matrix,
      // and toJson omits the key rather than writing null.
      expect(LatencyRow.fromJson(row.toJson()).scenarioId, isNull);
    });
  });
}
