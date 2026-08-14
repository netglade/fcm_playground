import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fcm_app/telemetry/drift_telemetry_buffer.dart';
import 'package:fcm_app/telemetry/push_telemetry.dart';
import 'package:fcm_app/telemetry/telemetry_buffer.dart';
import 'package:fcm_app/telemetry/telemetry_reporter.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixed_device_identity.dart';
import 'system_sqlite.dart';
import 'throwing_buffer.dart';

void main() {
  late DriftTelemetryBuffer database;
  late TelemetryBuffer buffer;

  /// Every request the reporter made, transport failures included, so a test can
  /// assert a flush was *attempted* and not only that the buffer looks right.
  late List<http.Request> requests;

  /// What the API answers, and whether anything is listening at all.
  late int status;
  late bool transportFails;

  /// Runs inside the in-flight request, which is where an event arriving during
  /// a flush arrives.
  late Future<void> Function()? whileFlushing;

  const identity = FixedDeviceIdentity('device-42');
  final baseUrl = Uri.parse('http://127.0.0.1:8080');

  TelemetryReporter reporterOn(TelemetryBuffer target) => TelemetryReporter(
    buffer: target,
    identity: identity,
    baseUrl: baseUrl,
    client: MockClient((request) async {
      requests.add(request);
      if (transportFails) {
        throw const SocketException('connection refused');
      }
      await whileFlushing?.call();

      return http.Response(
        jsonEncode({'recorded': _eventCountIn(request)}),
        status,
      );
    }),
  );

  late TelemetryReporter reporter;

  // `flutter test` is a Dart VM, not a device, so the plugin-bundled SQLite is
  // not there and the package's default library name is not on this machine.
  setUpAll(useSystemSqlite);

  setUp(() {
    database = DriftTelemetryBuffer(NativeDatabase.memory());
    // Held as the interface the reporter depends on, so nothing here can lean
    // on a Drift-only method the reporter could not have called.
    buffer = database;
    requests = [];
    status = 200;
    transportFails = false;
    whileFlushing = null;
    reporter = reporterOn(buffer);
  });

  tearDown(() => database.close());

  test('is a PushTelemetry, which is what the hooks depend on', () {
    // The four hooks take the interface so each can default to silence; this is
    // what keeps the real reporter substitutable for that default.
    expect(reporter, isA<PushTelemetry>());
  });

  group('record', () {
    test('stamps the device id and the time, so no hook has to', () async {
      // Stamped centrally so no hook has to remember either, and so a hook
      // cannot record a local-time event that reads as hours of latency.
      final before = DateTime.now().toUtc();

      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');

      final after = DateTime.now().toUtc();
      final recorded = (await buffer.pending()).single.event;
      expect(recorded.deviceId, 'device-42');
      expect(
        recorded.deviceId,
        await identity.id(),
        reason: 'the id comes from the identity, not from a constant',
      );
      // The bracket is the load-bearing part: `isUtc` below is guaranteed by
      // TelemetryEvent's constructor whatever is passed in, so on its own it
      // would pass for an epoch or a hard-coded stamp.
      expect(recorded.at.isBefore(before), isFalse);
      expect(
        recorded.at.isAfter(after),
        isFalse,
        reason: 'a real clock reading taken during the call',
      );
      expect(recorded.at.isUtc, isTrue);
    });

    test('carries the type, trace, scenario and detail through', () async {
      await reporter.record(
        TelemetryEventType.notReceived,
        traceId: 'tr-9',
        scenarioId: 'a1_notification_only',
        detail: 'nothing arrived',
      );

      final recorded = (await buffer.pending()).single.event;
      expect(recorded.type, TelemetryEventType.notReceived);
      expect(recorded.traceId, 'tr-9');
      expect(recorded.scenarioId, 'a1_notification_only');
      expect(recorded.detail, 'nothing arrived');
    });

    test('leaves an absent scenario absent rather than empty', () async {
      // A send made by hand has no scenario, and `''` is a different answer to
      // "which scenario produced this?" than "not from the gallery".
      await reporter.record(TelemetryEventType.receivedBg, traceId: 'tr-1');

      final recorded = (await buffer.pending()).single.event;
      expect(recorded.scenarioId, isNull);
      expect(recorded.detail, isNull);
    });

    test('does not send by itself', () async {
      // Whether a flush is safe here is the caller's knowledge, not the
      // reporter's: the background isolate can be killed mid-request, and the
      // event it was flushing would die with it. So recording only stores, and
      // the hooks that know they are in the foreground call flush().
      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');

      expect(requests, isEmpty);
      expect(await buffer.pending(), hasLength(1));
    });

    test('never throws, whatever the buffer does', () async {
      // record() is called from inside push handlers. A throw there would take
      // down delivery itself, which is a strictly worse outcome than lost
      // telemetry.
      final failing = ThrowingBuffer();

      await expectLater(
        reporterOn(
          failing,
        ).record(TelemetryEventType.receivedFg, traceId: 'tr-1'),
        completes,
      );
      expect(
        failing.attempted.single.traceId,
        'tr-1',
        reason:
            'the promise has to come from swallowing a real failure, not from '
            'a record() that stores nothing and therefore cannot fail',
      );
    });

    test('never throws when the device id cannot be read', () async {
      // The other half of the same promise: the id is read from the platform
      // store, which fails as readily as the database does.
      final reporter = TelemetryReporter(
        buffer: buffer,
        identity: const FixedDeviceIdentity.failing(),
        baseUrl: baseUrl,
        client: MockClient((request) async => http.Response('{}', 200)),
      );

      await expectLater(
        reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1'),
        completes,
      );
      expect(
        await buffer.pending(),
        isEmpty,
        reason: 'an event with no device id is not worth storing',
      );
    });
  });

  group('flush', () {
    test('posts the buffered events to /events', () async {
      await reporter.record(
        TelemetryEventType.receivedFg,
        traceId: 'tr-1',
        detail: 'fcm-message-1',
      );
      final stored = (await buffer.pending()).single.event;

      await reporter.flush();

      expect(requests.single.method, 'POST');
      expect(requests.single.url, Uri.parse('http://127.0.0.1:8080/events'));
      expect(
        requests.single.headers['content-type'],
        contains('application/json'),
      );
      expect(jsonDecode(requests.single.body), {
        'events': [stored.toJson()],
      });
    });

    test('keeps events when the flush fails, and retries them later', () async {
      // The whole reason for a buffer. Silently dropping telemetry is worse
      // than sending it late, because the missing row looks like a missing
      // delivery.
      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');
      transportFails = true;

      await reporter.flush();

      expect(
        requests,
        hasLength(1),
        reason:
            'the event is kept because this flush failed, not because no '
            'flush was ever attempted',
      );
      expect(await buffer.pending(), hasLength(1));

      transportFails = false;
      await reporter.flush();

      expect(requests, hasLength(2));
      expect(await buffer.pending(), isEmpty);
    });

    test('forgets events only on a 200', () async {
      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');
      status = 500;

      await reporter.flush();

      expect(requests, hasLength(1));
      expect(
        await buffer.pending(),
        hasLength(1),
        reason: 'a rejected batch is no evidence that it was stored',
      );

      // `POST /events` answers 200 with `{"recorded": n}` and nothing else, so
      // any other code is a proxy or a crash rather than an acknowledgement.
      status = 202;
      await reporter.flush();

      expect(await buffer.pending(), hasLength(1));

      status = 200;
      await reporter.flush();

      expect(await buffer.pending(), isEmpty);
    });

    test('keeps an event that arrives during a flush', () async {
      // The race `forget(events)` exists to survive: a blanket clear would lose
      // it, and so would forgetting whatever is pending once the reply is in.
      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');
      final sent = (await buffer.pending()).single.event;
      final arriving = TelemetryEvent(
        traceId: 'tr-2',
        type: TelemetryEventType.receivedBg,
        at: DateTime.utc(2026, 8, 13, 9, 30),
        deviceId: 'device-42',
      );
      whileFlushing = () => buffer.add(arriving);

      await reporter.flush();

      expect(
        jsonDecode(requests.single.body),
        {
          'events': [sent.toJson()],
        },
        reason: 'a flush carries what was pending when it began',
      );
      expect(
        [for (final entry in await buffer.pending()) entry.event],
        [arriving],
        reason: 'the acknowledged event is gone and the new one survived',
      );
    });

    test('keeps a duplicate that arrives during a flush', () async {
      // The sharper version of the test above: byte-identical rows are two
      // things that happened, because the buffer deliberately does not
      // deduplicate, so a forget that matched on columns would delete the
      // arrival along with the row that was acknowledged.
      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');
      final sent = (await buffer.pending()).single;
      whileFlushing = () => buffer.add(sent.event);

      await reporter.flush();

      final left = await buffer.pending();
      expect(left.single.event, sent.event);
      expect(
        left.single.id,
        isNot(sent.id),
        reason: 'the surviving row is the one that was never sent',
      );
    });

    test('does not flush when there is nothing pending', () async {
      await reporter.flush();

      expect(requests, isEmpty, reason: 'an empty POST is a wasted request');

      await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');
      await reporter.flush();

      expect(
        requests,
        hasLength(1),
        reason:
            'it is emptiness that suppresses the request, not a reporter that '
            'never flushes at all',
      );

      await reporter.flush();

      expect(
        requests,
        hasLength(1),
        reason: 'and an acknowledged buffer is empty again',
      );
    });
  });
}

/// How many events the request body carries, for the `recorded` count the API
/// answers with.
int _eventCountIn(http.Request request) {
  final decoded = jsonDecode(request.body);
  if (decoded is! Map<String, Object?>) {
    return 0;
  }

  final events = decoded['events'];

  return events is List ? events.length : 0;
}
