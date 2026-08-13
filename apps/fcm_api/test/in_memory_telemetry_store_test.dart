import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryTelemetryStore store;

  setUp(() => store = InMemoryTelemetryStore());

  // `sentAt` and `arrivalAt` build the two halves of a latency pair, so each
  // test reads as the timeline it is about.
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
    String? scenarioId,
  }) => TelemetryEvent(
    traceId: trace,
    type: type,
    at: at,
    deviceId: device,
    scenarioId: scenarioId,
  );

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

    test('reads events back in the order they were recorded', () async {
      // Deliberately the same instant: the API stamps `queued` and `sent` from
      // one clock, so an order derived from `at` would be arbitrary and a
      // caller could not tell a send from its own queueing.
      final at = DateTime.utc(2026, 8, 13, 9, 30);
      await store.record([
        TelemetryEvent(
          traceId: 'tr-1',
          type: TelemetryEventType.queued,
          at: at,
          deviceId: '',
        ),
        sentAt('tr-1', at),
      ]);

      expect((await store.all()).map((e) => e.type), [
        TelemetryEventType.queued,
        TelemetryEventType.sent,
      ]);
    });

    test('reads events back in recorded order, not in timestamp order', () async {
      // A device that was offline flushes older events after a device that was
      // not, so recorded order and time order genuinely differ. Without this,
      // a store that sorted by `at` would still pass the test above, whose two
      // events share an instant and so survive any stable sort.
      await store.record([
        arrivalAt('tr-1', 'dev-a', DateTime.utc(2026, 8, 13, 9, 5)),
      ]);
      await store.record([
        arrivalAt('tr-2', 'dev-b', DateTime.utc(2026, 8, 13, 9, 1)),
      ]);

      expect((await store.all()).map((e) => e.deviceId), ['dev-a', 'dev-b']);
    });

    test(
      'ignores a duplicate of the same event from the same device',
      () async {
        // The retry case: a flush that succeeded server-side but whose
        // acknowledgement was lost is sent again. Without this the latency is
        // computed twice and any average over it is wrong.
        await store.record([event]);
        await store.record([event]);

        expect(await store.all(), [event]);
      },
    );

    test('ignores a duplicate re-sent with a later timestamp', () async {
      // The key is (trace, type, device) and deliberately excludes `at`: a
      // client that re-stamps an event on retry is still reporting the one
      // arrival, and a second row for it would double-count the delivery.
      await store.record([event]);
      await store.record([
        arrivalAt('tr-1', 'dev-1', event.at.add(const Duration(seconds: 30))),
      ]);

      expect(await store.all(), [event]);
    });

    test('keeps the earliest timestamp when a re-send arrives first', () async {
      // The same rule seen from the other side, so the surviving row is the
      // earliest observation rather than whichever arrived first.
      final later = arrivalAt(
        'tr-1',
        'dev-1',
        event.at.add(const Duration(seconds: 30)),
      );
      await store.record([later]);
      await store.record([event]);

      expect(await store.all(), [event]);
    });

    test('keeps the same event type from two different devices', () async {
      // The matrix's whole point: two phones receiving one broadcast are two
      // rows, not a duplicate.
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
      // One device produces a whole timeline for one trace, so the type is
      // part of the key rather than something collapsed away.
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
  });

  group('latencies', () {
    test('pairs sent with the arrival, one row per device', () async {
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
        arrivalAt('tr-1', 'fast', DateTime.utc(2026, 8, 13, 9, 0, 1)),
        arrivalAt('tr-1', 'slow', DateTime.utc(2026, 8, 13, 9, 4, 12)),
      ]);

      final rows = await store.latencies();

      expect(rows, hasLength(2));
      expect(
        rows.map((row) => (row.deviceId, row.latency)).toSet(),
        // Not `const`: a Duration has no primitive equality, so it cannot be a
        // constant set element. Still wrapped in `equals` so the formatter and
        // `prefer-trailing-comma` agree on the layout.
        equals({
          ('fast', const Duration(seconds: 1)),
          ('slow', const Duration(minutes: 4, seconds: 12)),
        }),
      );
      expect(rows.map((row) => row.traceId).toSet(), equals(const {'tr-1'}));
    });

    test('keeps one trace apart from another for the same device', () async {
      // Two sends to one handset are two measurements; keying on the device
      // alone would silently keep whichever was recorded last.
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

    test(
      'still takes the earliest when the later arrival is recorded last',
      () async {
        // The same two arrivals the other way round. Without this pair, an
        // implementation that simply keeps the *last* arrival it sees passes
        // the test above by accident — and the useful figure is
        // time-to-first-delivery, which is what a duplicate delivery would
        // otherwise inflate.
        await store.record([
          sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
          arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 2)),
          arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 5)),
        ]);

        expect(
          (await store.latencies()).single.latency,
          const Duration(seconds: 2),
        );
      },
    );

    test('takes the earlier of a foreground and a background arrival', () async {
      // Two *different* types, so the idempotency key leaves both stored and
      // the pairing itself has to compare across them — this is the only test
      // that can see that comparison, because same-type duplicates are already
      // collapsed by `record`. Asserted in both recording orders: with one
      // only, an implementation keeping whichever arrival it saw last (or
      // first) passes by accident.
      Future<List<LatencyRow>> rowsFor(List<TelemetryEvent> arrivals) async {
        final subject = InMemoryTelemetryStore();
        await subject.record([
          sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
          ...arrivals,
        ]);

        return subject.latencies();
      }

      final foreground = arrivalAt(
        'tr-1',
        'dev',
        DateTime.utc(2026, 8, 13, 9, 0, 5),
      );
      final background = arrivalAt(
        'tr-1',
        'dev',
        DateTime.utc(2026, 8, 13, 9, 0, 2),
        type: TelemetryEventType.receivedBg,
      );

      for (final order in [
        [foreground, background],
        [background, foreground],
      ]) {
        final rows = await rowsFor(order);

        expect(rows, hasLength(1), reason: 'one row per device, not per event');
        expect(
          rows.single.latency,
          const Duration(seconds: 2),
          reason: 'recorded as ${order.map((e) => e.type.wireName)}',
        );
      }
    });

    test('reports a backwards clock as skew rather than clamping it', () async {
      // Asserted through the store, not on a hand-built row: clamping or
      // discarding a negative pair here is exactly the mistake, and a test that
      // only ever constructs its own row cannot see it.
      await store.record([
        sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 5)),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 0)),
      ]);

      final row = (await store.latencies()).single;
      expect(row.isSkewed, isTrue);
      expect(row.latency, const Duration(seconds: -5));
    });

    test('omits a trace with no arrival, rather than reporting zero', () async {
      // Not-delivered is a distinct state from delivered-instantly, and the
      // matrix must be able to tell them apart.
      await store.record([sentAt('tr-1', DateTime.utc(2026, 8, 13, 9))]);

      expect(await store.latencies(), isEmpty);
    });

    test('omits an arrival whose send was never recorded here', () async {
      // A push sent by hand produces no `sent` row, so there is nothing to
      // measure from. The arrival is still kept as evidence of delivery.
      await store.record([
        arrivalAt('never-sent', 'dev', DateTime.utc(2026, 8, 13, 9)),
      ]);

      expect(await store.latencies(), isEmpty);
      expect(await store.all(), hasLength(1));
    });

    test('carries the scenario id from whichever side knew it', () async {
      // The API knows it when the send came from the gallery; the device knows
      // it from the payload. A row with neither is a row nobody can group.
      await store.record([
        sentAt(
          'tr-1',
          DateTime.utc(2026, 8, 13, 9, 0, 0),
          scenarioId: 'a1_notification_only',
        ),
        arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 1)),
        sentAt('tr-2', DateTime.utc(2026, 8, 13, 9, 5, 0)),
        arrivalAt(
          'tr-2',
          'dev',
          DateTime.utc(2026, 8, 13, 9, 5, 1),
          scenarioId: 'b1_data_only',
        ),
      ]);

      expect(
        (await store.latencies())
            .map((row) => (row.traceId, row.scenarioId))
            .toSet(),
        equals(const {
          ('tr-1', 'a1_notification_only'),
          ('tr-2', 'b1_data_only'),
        }),
      );
    });

    test('is empty on a store nothing was recorded into', () async {
      expect(await store.latencies(), isEmpty);
      expect(await store.all(), isEmpty);
    });
  });
}
