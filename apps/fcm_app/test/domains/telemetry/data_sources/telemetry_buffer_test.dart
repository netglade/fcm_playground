import 'package:drift/native.dart';
import 'package:fcm_app/domains/telemetry/data_sources/drift_telemetry_buffer.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_buffer.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../system_sqlite.dart';

void main() {
  late DriftTelemetryBuffer database;
  late TelemetryBuffer buffer;

  // `flutter test` is a Dart VM, not a device, so the plugin-bundled SQLite is
  // not there and the package's default library name is not on this machine.
  setUpAll(useSystemSqlite);

  setUp(() {
    database = DriftTelemetryBuffer(NativeDatabase.memory());
    // Assigned through the interface, so the assignment itself pins that the Drift
    // implementation satisfies it.
    buffer = database;
  });

  tearDown(() => database.close());

  final first = _eventAt(DateTime.utc(2026, 8, 13, 9, 1));
  final second = _eventAt(DateTime.utc(2026, 8, 13, 9, 2));

  test('keeps events until they are forgotten', () async {
    await buffer.add(first);

    final read = await buffer.pending();
    final reread = await buffer.pending();

    expect(_eventsOf(read), [first]);
    expect(_eventsOf(reread), [first], reason: 'reading is not consuming');
    expect(read.single.id, isA<int>());
    expect(
      reread.single.id,
      read.single.id,
      reason: 'the identity a flush forgets by is stable across reads',
    );
  });

  test('forgets only what it is given', () async {
    // A blanket clear after a partial flush loses whatever arrived meanwhile.
    await buffer.add(first);
    await buffer.add(second);

    await buffer.forget([(await buffer.pending()).first]);

    expect(_eventsOf(await buffer.pending()), [second]);
  });

  test('forgets the newest event when that is the one it is given', () async {
    // Fails an implementation that ignores its argument and drops the oldest n.
    await buffer.add(first);
    await buffer.add(second);

    await buffer.forget([(await buffer.pending()).last]);

    expect(_eventsOf(await buffer.pending()), [first]);
  });

  test('forgets one of two identical events, not both', () async {
    // Two byte-identical rows are two things that happened, so an implementation
    // deleting by matching columns would take both.
    await buffer.add(first);
    await buffer.add(first);

    final pending = await buffer.pending();
    expect(_eventsOf(pending), [first, first]);

    await buffer.forget([pending.first]);

    final left = await buffer.pending();
    expect(_eventsOf(left), [first]);
    expect(
      left.single.id,
      pending.last.id,
      reason: 'the row that survived is the one that was not acknowledged',
    );
  });

  test(
    'keeps the events past the limit when a bounded flush is forgotten',
    () async {
      // A flush sends `limit` events and forgets those, so anything the limit
      // excluded — identical rows included — must survive.
      await buffer.add(first);
      await buffer.add(first);
      await buffer.add(first);

      await buffer.forget(await buffer.pending(limit: 2));

      expect(_eventsOf(await buffer.pending()), [first]);
    },
  );

  test('forgetting nothing changes nothing', () async {
    // A flush with an empty batch is not an error, and `id IN ()` is not SQL.
    await buffer.add(first);

    await buffer.forget([]);

    expect(_eventsOf(await buffer.pending()), [first]);
  });

  test('bounds a flush, so a week offline is not one huge request', () async {
    for (var i = 0; i < 250; i++) {
      await buffer.add(_eventNumbered(i));
    }

    expect(await buffer.pending(limit: 200), hasLength(200));
    expect(
      await buffer.pending(),
      hasLength(200),
      reason: 'the default bounds a flush even when no caller passes a limit',
    );
  });

  test(
    'returns events oldest first, so latency is computed in order',
    () async {
      await buffer.add(_eventAt(DateTime.utc(2026, 8, 13, 9, 5)));
      await buffer.add(_eventAt(DateTime.utc(2026, 8, 13, 9, 1)));

      expect(
        _eventsOf(await buffer.pending()).map((e) => e.at),
        [DateTime.utc(2026, 8, 13, 9, 1), DateTime.utc(2026, 8, 13, 9, 5)],
        reason:
            'insertion order is the reverse here, so it cannot pass by luck',
      );
    },
  );

  test(
    'bounds a flush to the oldest events, not to the first inserted',
    () async {
      // Ordering and the limit have to compose: a query that limits before it
      // sorts returns the two rows inserted first, which are the wrong two.
      await buffer.add(_eventAt(DateTime.utc(2026, 8, 13, 9, 5)));
      await buffer.add(_eventAt(DateTime.utc(2026, 8, 13, 9, 1)));
      await buffer.add(_eventAt(DateTime.utc(2026, 8, 13, 9, 3)));

      expect(_eventsOf(await buffer.pending(limit: 2)).map((e) => e.at), [
        DateTime.utc(2026, 8, 13, 9, 1),
        DateTime.utc(2026, 8, 13, 9, 3),
      ]);
    },
  );

  test('orders events stamped at the same instant by arrival', () async {
    // Hooks that fire in one turn share a clock reading, so `at` alone does not
    // order them and the result would otherwise be whatever SQLite chose.
    final at = DateTime.utc(2026, 8, 13, 9, 1);
    await buffer.add(_eventAt(at, detail: 'earlier'));
    await buffer.add(_eventAt(at, detail: 'later'));

    expect(_eventsOf(await buffer.pending()).map((e) => e.detail), [
      'earlier',
      'later',
    ]);
  });

  test(
    'round-trips every field, including a null scenario and detail',
    () async {
      // The nullable columns are where a hand-written mapper goes wrong.
      final full = TelemetryEvent(
        traceId: 'tr-7',
        type: TelemetryEventType.notReceived,
        at: DateTime.utc(2026, 8, 13, 9, 1, 2, 345),
        deviceId: 'device-7',
        scenarioId: 'b6_token_refresh',
        detail: 'foreground',
      );
      final bare = TelemetryEvent(
        traceId: 'tr-8',
        type: TelemetryEventType.receivedBg,
        at: DateTime.utc(2026, 8, 13, 9, 1, 3),
        deviceId: 'device-7',
      );

      await buffer.add(full);
      await buffer.add(bare);

      final read = _eventsOf(await buffer.pending());
      expect(read, [full, bare]);
      expect(read.first.traceId, 'tr-7');
      expect(read.first.type, TelemetryEventType.notReceived);
      expect(read.first.at, DateTime.utc(2026, 8, 13, 9, 1, 2, 345));
      expect(read.first.at.isUtc, isTrue);
      expect(read.first.deviceId, 'device-7');
      expect(read.first.scenarioId, 'b6_token_refresh');
      expect(read.first.detail, 'foreground');
      expect(
        read.last.scenarioId,
        isNull,
        reason:
            'a send made by hand has no scenario, and "" is a different answer',
      );
      expect(read.last.detail, isNull);
    },
  );

  test(
    'keeps sub-second precision, so a latency is not rounded away',
    () async {
      // Drift stores a DateTime column as whole Unix seconds by default, which
      // would floor every stamp and make a sub-second delivery read as zero.
      final at = DateTime.utc(2026, 8, 13, 9, 1, 2, 345, 678);

      await buffer.add(_eventAt(at));

      final stored = _eventsOf(await buffer.pending()).single.at;
      expect(stored, at);
      expect(stored.millisecond, isA<int>());
      expect(stored.millisecond, 345);
      expect(stored.microsecond, isA<int>());
      expect(stored.microsecond, 678);
    },
  );
}

/// An arrival stamped at [at], with everything else held constant.
TelemetryEvent _eventAt(DateTime at, {String detail = 'fcm-message-1'}) =>
    TelemetryEvent(
      traceId: 'tr-1',
      type: TelemetryEventType.receivedFg,
      at: at,
      deviceId: 'device-1',
      detail: detail,
    );

/// A distinct event per [index], one second apart.
TelemetryEvent _eventNumbered(int index) => TelemetryEvent(
  traceId: 'tr-$index',
  type: TelemetryEventType.receivedFg,
  at: DateTime.utc(2026, 8, 13, 9).add(Duration(seconds: index)),
  deviceId: 'device-1',
);

List<TelemetryEvent> _eventsOf(List<PendingEvent> pending) => [
  for (final entry in pending) entry.event,
];
