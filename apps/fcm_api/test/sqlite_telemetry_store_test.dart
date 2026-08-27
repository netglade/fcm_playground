import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'sqlite_availability.dart';

void main() {
  // Probed once, at registration time, so every test in the group carries the
  // same verdict.
  final skipReason = sqliteAvailability();

  // The same expectations the in-memory suite pins, against a real database,
  // plus what only a file can show. The pairing is shared code, so these latency
  // tests check that storage returns what it was given.
  group('SqliteTelemetryStore', _storeBehaviour, skip: skipReason);
}

/// Hoisted out of the `group` call so it fits on one line — `dart format` and
/// `prefer-trailing-comma` cannot both be satisfied inline.
void _storeBehaviour() {
  late Directory directory;
  late String databasePath;
  late SqliteTelemetryStore store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fcm_telemetry_sqlite_');
    databasePath = '${directory.path}/events.sqlite';
    store = SqliteTelemetryStore.open(databasePath);
  });

  tearDown(() async {
    await store.close();
    directory.deleteSync(recursive: true);
  });

  TelemetryEvent sentAt(String trace, DateTime at, {String? scenarioId}) =>
      TelemetryEvent(
        traceId: trace,
        type: TelemetryEventType.sent,
        at: at,
        deviceId: '',
        scenarioId: scenarioId,
      );

  TelemetryEvent arrivalAt(
    String trace,
    String device,
    DateTime at, {
    TelemetryEventType type = TelemetryEventType.receivedFg,
  }) => TelemetryEvent(traceId: trace, type: type, at: at, deviceId: device);

  final at9 = DateTime.utc(2026, 8, 13, 9);

  final event = TelemetryEvent(
    traceId: 'tr-1',
    type: TelemetryEventType.receivedFg,
    at: DateTime.utc(2026, 8, 13, 9, 30),
    deviceId: 'dev-1',
  );

  group('record', () {
    test('records events and reads them back', () async {
      await store.record([event]);

      expect(await store.all(), [event]);
    });

    test(
      'reads events back in recorded order, not in timestamp order',
      () async {
        // An offline device flushes older events after a live one, so a store
        // ordering by `at` or by primary key fails here.
        await store.record([
          arrivalAt('tr-1', 'dev-a', DateTime.utc(2026, 8, 13, 9, 5)),
        ]);
        await store.record([
          arrivalAt('tr-2', 'dev-b', DateTime.utc(2026, 8, 13, 9, 1)),
        ]);

        expect((await store.all()).map((e) => e.deviceId), ['dev-a', 'dev-b']);
      },
    );

    test(
      'ignores a duplicate of the same event from the same device',
      () async {
        await store.record([event]);
        await store.record([event]);

        expect(await store.all(), [event]);
      },
    );

    test('ignores a duplicate re-sent with a later timestamp', () async {
      // The key is (trace, type, device), excluding `at`; the earliest
      // observation wins.
      await store.record([event]);
      await store.record([
        arrivalAt('tr-1', 'dev-1', event.at.add(const Duration(seconds: 30))),
      ]);

      expect(await store.all(), [event]);
    });

    test('keeps the earliest timestamp when a re-send arrives first', () async {
      final later = arrivalAt(
        'tr-1',
        'dev-1',
        event.at.add(const Duration(seconds: 30)),
      );
      await store.record([later]);
      await store.record([event]);

      expect(await store.all(), [event]);
    });

    test(
      'keeps the earliest when the duplicate is a microsecond later',
      () async {
        // Earliest-wins is decided in SQL, so the column type decides correctness:
        // as text these two compare backwards, '…02.000001Z' sorting first.
        await store.record([arrivalAt('tr-1', 'dev', at9)]);
        await store.record([
          arrivalAt('tr-1', 'dev', at9.add(const Duration(microseconds: 1))),
        ]);

        expect((await store.all()).single.at, at9);
      },
    );

    test('keeps the same event type from two different devices', () async {
      // Two phones on one broadcast are two rows, not a duplicate.
      await store.record([
        event,
        TelemetryEvent(
          traceId: event.traceId,
          type: event.type,
          at: event.at,
          deviceId: 'other-device',
        ),
      ]);

      expect(await store.all(), hasLength(2));
    });

    test('keeps two event types from one device', () async {
      await store.record([
        event,
        TelemetryEvent(
          traceId: event.traceId,
          type: TelemetryEventType.displayed,
          at: event.at,
          deviceId: event.deviceId,
        ),
      ]);

      expect((await store.all()).map((e) => e.type), [
        TelemetryEventType.receivedFg,
        TelemetryEventType.displayed,
      ]);
    });

    test('round-trips every field, including the optional two', () async {
      // `''` read back for a written `null` would group a hand-made send with the
      // gallery's rows.
      final full = TelemetryEvent(
        traceId: 'tr-1',
        type: TelemetryEventType.sendFailed,
        at: DateTime.utc(2026, 8, 13, 9, 30, 15, 250, 123),
        deviceId: 'dev-1',
        scenarioId: 'a1_notification_only',
        detail: 'UNREGISTERED',
      );
      await store.record([full, event]);

      final stored = await store.all();
      expect(stored, [full, event]);
      expect(stored.first.at.microsecond, 123, reason: 'no lost precision');
      expect(stored.last.scenarioId, isNull);
      expect(stored.last.detail, isNull);
    });
  });

  group('latencies', () {
    test('pairs sent with the arrival, one row per device', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
        arrivalAt('tr-1', 'fast', DateTime.utc(2026, 8, 13, 9, 0, 1)),
        arrivalAt('tr-1', 'slow', DateTime.utc(2026, 8, 13, 9, 4, 12)),
      ]);

      expect(
        (await store.latencies())
            .map((row) => (row.deviceId, row.latency))
            .toSet(),
        // `equals` so the formatter and `prefer-trailing-comma` agree; a
        // Duration cannot be a const set element.
        equals({
          ('fast', const Duration(seconds: 1)),
          ('slow', const Duration(minutes: 4, seconds: 12)),
        }),
      );
    });

    test('keeps one trace apart from another for the same device', () async {
      // Two sends to one handset are two measurements. A key without `trace_id`
      // would keep the last, and every test above uses one trace.
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 1)),
        sentAt('tr-2', DateTime.utc(2026, 8, 13, 9, 5, 0)),
        arrivalAt('tr-2', 'dev', DateTime.utc(2026, 8, 13, 9, 5, 3)),
      ]);

      expect(
        (await store.latencies())
            .map((row) => (row.traceId, row.latency))
            .toSet(),
        equals({
          ('tr-1', const Duration(seconds: 1)),
          ('tr-2', const Duration(seconds: 3)),
        }),
      );
    });

    test('takes the earliest arrival when a message arrives twice', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 5)),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 2)),
      ]);

      expect(
        (await store.latencies()).single.latency,
        const Duration(seconds: 2),
      );
    });

    test('takes the earlier of a foreground and a background arrival', () async {
      // Two types, so both survive the key and the pairing must compare across
      // them. Asserted in both recording orders.
      for (final order in [
        [TelemetryEventType.receivedFg, TelemetryEventType.receivedBg],
        [TelemetryEventType.receivedBg, TelemetryEventType.receivedFg],
      ]) {
        final subject = SqliteTelemetryStore.open(
          '${directory.path}/${order.first.wireName}.sqlite',
        );
        await subject.record([
          sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
          arrivalAt(
            'tr-1',
            'dev',
            DateTime.utc(2026, 8, 13, 9, 0, 5),
            type: order.first,
          ),
          arrivalAt(
            'tr-1',
            'dev',
            DateTime.utc(2026, 8, 13, 9, 0, 2),
            type: order.last,
          ),
        ]);

        final rows = await subject.latencies();
        expect(rows, hasLength(1), reason: 'one row per device, not per event');
        expect(
          rows.single.latency,
          const Duration(seconds: 2),
          reason: 'recorded as ${order.map((t) => t.wireName)}',
        );
        await subject.close();
      }
    });

    test('reports a backwards clock as skew rather than clamping it', () async {
      // Clamping would turn a measurement error into a false result, and a
      // "1ms on Xiaomi" would discredit every other number in the matrix.
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 5)),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 0)),
      ]);

      final row = (await store.latencies()).single;
      expect(row.isSkewed, isTrue);
      expect(row.latency, const Duration(seconds: -5));
    });

    test('omits a trace with no arrival, rather than reporting zero', () async {
      await store.record([sentAt('tr-1', at9)]);

      expect(await store.latencies(), isEmpty);
    });

    test('omits an arrival whose send was never recorded here', () async {
      // A hand-made send has no `sent` row to measure from. The arrival is still
      // kept as evidence of delivery.
      await store.record([arrivalAt('never-sent', 'dev', at9)]);

      expect(await store.latencies(), isEmpty);
      expect(await store.all(), hasLength(1));
    });

    test('carries the scenario id from the sending side', () async {
      await store.record([
        sentAt('tr-1', at9, scenarioId: 'a1_notification_only'),
        arrivalAt('tr-1', 'dev', at9.add(const Duration(seconds: 1))),
      ]);

      expect(
        (await store.latencies()).single.scenarioId,
        'a1_notification_only',
      );
    });

    test('is empty on a database nothing was recorded into', () async {
      expect(await store.latencies(), isEmpty);
      expect(await store.all(), isEmpty);
    });
  });

  group('record reports how many were newly stored', () {
    test('counts each new key once', () async {
      expect(
        await store.record([
          sentAt('tr-1', at9),
          arrivalAt('tr-1', 'dev', at9),
        ]),
        2,
      );
    });

    test('counts zero for a replayed batch', () async {
      await store.record([sentAt('tr-1', at9)]);

      expect(await store.record([sentAt('tr-1', at9)]), 0);
    });

    test('counts zero for a re-stamped duplicate, not one', () async {
      await store.record([arrivalAt('tr-1', 'dev', at9)]);

      expect(
        await store.record([
          arrivalAt('tr-1', 'dev', at9.subtract(const Duration(seconds: 5))),
        ]),
        0,
      );
    });

    test('counts only the new members of a mixed batch', () async {
      await store.record([sentAt('tr-1', at9)]);

      expect(
        await store.record([
          sentAt('tr-1', at9),
          arrivalAt('tr-1', 'dev', at9),
        ]),
        1,
      );
    });

    test('counts a duplicate inside one batch once', () async {
      // A buffer flushed twice can hold the same event twice in one request.
      expect(await store.record([event, event]), 1);
    });
  });

  group('persistence', () {
    test('keeps events across closing and reopening the file', () async {
      // The one behaviour the in-memory store cannot have.
      final full = TelemetryEvent(
        traceId: 'tr-1',
        type: TelemetryEventType.sent,
        at: DateTime.utc(2026, 8, 13, 9, 0, 0, 250, 123),
        deviceId: '',
        scenarioId: 'a1_notification_only',
        detail: 'projects/p/messages/123',
      );
      await store.record([
        full,
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 1)),
      ]);
      await store.close();

      store = SqliteTelemetryStore.open(databasePath);

      expect((await store.all()).first, full);
      expect(
        (await store.latencies()).single.latency,
        const Duration(milliseconds: 749, microseconds: 877),
        reason: 'a reopened row keeps its full precision',
      );
    });

    test('still suppresses a duplicate flushed after a restart', () async {
      // Across a restart: idempotency held only in memory would double-count.
      await store.record([event]);
      await store.close();

      store = SqliteTelemetryStore.open(databasePath);

      expect(await store.record([event]), 0);
      expect(await store.all(), [event]);
    });

    test('leaves an existing file alone when it opens it', () async {
      // `CREATE TABLE IF NOT EXISTS`, not `DROP TABLE`: a wiping schema step
      // would lose every send on every restart, and every test above writes
      // first.
      await store.record([event]);
      await store.close();

      await SqliteTelemetryStore.open(databasePath).close();
      store = SqliteTelemetryStore.open(databasePath);

      expect(await store.all(), [event]);
    });
  });

  group('recent', () {
    test('answers newest first, which all() deliberately does not', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0)),
        sentAt('tr-2', DateTime.utc(2026, 8, 13, 9, 1)),
      ]);

      // Newest first, unlike `all()`'s recorded order. Both are wanted; this is
      // the one a screen reads.
      expect((await store.recent()).map((event) => event.traceId), [
        'tr-2',
        'tr-1',
      ]);
    });

    test('stops at the limit, keeping the newest', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0)),
        sentAt('tr-2', DateTime.utc(2026, 8, 13, 9, 1)),
        sentAt('tr-3', DateTime.utc(2026, 8, 13, 9, 2)),
      ]);

      // The *newest* two: taking the first two would satisfy a length assertion
      // and answer the wrong question.
      expect((await store.recent(limit: 2)).map((event) => event.traceId), [
        'tr-3',
        'tr-2',
      ]);
    });

    test('agrees with all() about content, one reversal apart', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0)),
        arrivalAt('tr-1', 'dev-a', DateTime.utc(2026, 8, 13, 9, 1)),
      ]);

      // A `recent` dropping a column or row would pass both tests above; value
      // equality compares contents.
      expect(await store.recent(), (await store.all()).reversed.toList());
    });
  });

  group('eventsForTraces', () {
    TelemetryEvent event(String traceId, TelemetryEventType type) =>
        TelemetryEvent(
          traceId: traceId,
          type: type,
          at: DateTime.utc(2026, 8, 17, 9, 0),
          deviceId: '',
        );

    test('returns only the traces asked for, in recorded order', () async {
      await store.record([
        event('tr-1', TelemetryEventType.queued),
        event('tr-2', TelemetryEventType.queued),
        event('tr-1', TelemetryEventType.sent),
      ]);

      final events = await store.eventsForTraces(['tr-1']);

      expect(events.map((e) => e.type), [
        TelemetryEventType.queued,
        TelemetryEventType.sent,
      ]);
    });

    test('answers empty for a trace it has never seen', () async {
      expect(await store.eventsForTraces(['tr-9']), isEmpty);
    });

    test('answers empty for an empty request rather than everything', () async {
      await store.record([event('tr-1', TelemetryEventType.queued)]);

      expect(await store.eventsForTraces([]), isEmpty);
    });
  });
}
