import 'dart:async';
import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Handler handlerWith(FakeFcmSender sender) => ApiRouter(
    sender: sender,
    now: () => sentAt,
    newTraceId: () => 'tr-1',
    telemetry: InMemoryTelemetryStore(),
    scheduler: SendScheduler(
      runs: InMemoryRunStore(),
      telemetry: InMemoryTelemetryStore(),
      sender: sender,
      newId: () => 'run-1',
      now: () => sentAt,
    ),
  ).handler;

  FutureOr<Response> post(Object? body, {FakeFcmSender? sender}) =>
      handlerWith(sender ?? FakeFcmSender())(
        Request(
          'POST',
          Uri.parse('http://localhost:8080/send'),
          body: body is String ? body : jsonEncode(body),
          headers: const {'content-type': 'application/json'},
        ),
      );

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  /// A router over a store the caller can seed, which `handlerWith` cannot give:
  /// it builds a fresh store per call, so nothing recorded before the request is
  /// visible to the handler. Follows the pattern the send-side test above already uses.
  ({Handler handler, InMemoryTelemetryStore store}) routerOverStore() {
    final store = InMemoryTelemetryStore();
    final sender = FakeFcmSender();

    return (
      handler: ApiRouter(
        sender: sender,
        now: () => sentAt,
        newTraceId: () => 'tr-1',
        telemetry: store,
        scheduler: SendScheduler(
          runs: InMemoryRunStore(),
          telemetry: store,
          sender: sender,
          newId: () => 'run-1',
          now: () => sentAt,
        ),
      ).handler,
      store: store,
    );
  }

  Map<String, Object?> validBody({String token = 'device-token'}) => {
    'token': token,
    'message': {
      'notification': {'title': 'Build finished'},
    },
  };

  group('GET /health', () {
    test('answers 200 so the server can be checked without sending', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/health')),
      );

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {'status': 'ok'});
    });
  });

  group('POST /send', () {
    test('answers 200 with the stamped id, timestamp and trace', () async {
      final response = await post(validBody());

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {
        'messageId': 'projects/p/messages/0:17',
        'sentAt': '2026-08-11T09:12:03.000Z',
        'traceId': 'tr-1',
      });
    });

    test('sends the trace id on to FCM inside data', () async {
      // The route is the only path a real send takes, so the injection has to hold
      // end to end.
      final sender = FakeFcmSender();

      await post(validBody(), sender: sender);

      final message = sender.sent.single['message']! as Map<String, Object?>;
      expect(message['data'], {'trace_id': 'tr-1'});
    });

    test('records the send into the store the router was given', () async {
      // The route has to reach the *same* store `GET /latency` reads from: one that
      // recorded into a store of its own would answer an empty latency page forever.
      final store = InMemoryTelemetryStore();
      final sender = FakeFcmSender();
      final handler = ApiRouter(
        sender: sender,
        now: () => sentAt,
        newTraceId: () => 'tr-1',
        telemetry: store,
        scheduler: SendScheduler(
          runs: InMemoryRunStore(),
          telemetry: store,
          sender: sender,
          newId: () => 'run-1',
          now: () => sentAt,
        ),
      ).handler;

      await handler(
        Request(
          'POST',
          Uri.parse('http://localhost:8080/send'),
          body: jsonEncode(validBody()),
          headers: const {'content-type': 'application/json'},
        ),
      );

      expect((await store.all()).map((e) => (e.traceId, e.type)), [
        ('tr-1', TelemetryEventType.queued),
        ('tr-1', TelemetryEventType.sent),
      ]);
    });

    test('answers JSON', () async {
      final response = await post(validBody());

      expect(response.headers['content-type'], startsWith('application/json'));
    });

    test('answers 400 when the body is not JSON at all', () async {
      final response = await post('not json');

      expect(response.statusCode, 400);
      expect(await bodyOf(response), contains('error'));
    });

    test('answers 400 when the body is a JSON array', () async {
      final response = await post([1, 2, 3]);

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('object'));
    });

    test(
      'answers 400 with the field path for an unknown message field',
      () async {
        final response = await post({
          'token': 'device-token',
          'message': {
            'notification': {'titel': 'typo'},
          },
        });

        expect(response.statusCode, 400);
        expect(
          (await bodyOf(response))['error'],
          contains('notification: unknown field "titel"'),
        );
      },
    );

    test('answers 400 for a blank token, not 500', () async {
      // The blankness check moved into SendTarget.readFrom, so this asserts the
      // FormatException it throws still reaches the caller as a 400.
      final response = await post(validBody(token: '  '));

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('blank'));
    });

    test('answers 400 when the body names no delivery target', () async {
      final response = await post({
        'message': {
          'notification': {'title': 'Build finished'},
        },
      });

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('target is required'));
    });

    test('answers 501 for all_devices, having sent nothing', () async {
      final sender = FakeFcmSender();
      final body = {
        'all_devices': true,
        'message': {
          'notification': {'title': 'Build finished'},
        },
      };

      final response = await post(body, sender: sender);

      expect(response.statusCode, 501);
      expect(sender.sent, isEmpty, reason: 'nothing may be sent');
    });

    test('answers 404 for an unregistered token', () async {
      final response = await post(
        validBody(),
        sender: FakeFcmSender(
          failure: const FcmSendException(
            status: 'UNREGISTERED',
            message: 'Requested entity was not found.',
          ),
        ),
      );

      expect(response.statusCode, 404);
      expect((await bodyOf(response))['error'], contains('no longer valid'));
    });

    test('answers 502 when FCM fails for any other reason', () async {
      final response = await post(
        validBody(),
        sender: FakeFcmSender(
          failure: const FcmSendException(
            status: 'INTERNAL',
            message: 'Backend error.',
          ),
        ),
      );

      expect(response.statusCode, 502);
    });
  });

  group('GET /events', () {
    TelemetryEvent queuedAt(String trace, DateTime at) => TelemetryEvent(
      traceId: trace,
      type: TelemetryEventType.queued,
      at: at,
      deviceId: '',
    );

    test('answers the recent events, newest first', () async {
      final api = routerOverStore();
      await api.store.record([
        queuedAt('tr-1', DateTime.utc(2026, 8, 18, 9, 30)),
        queuedAt('tr-2', DateTime.utc(2026, 8, 18, 9, 31)),
      ]);

      final response = await api.handler(
        Request('GET', Uri.parse('http://localhost:8080/events')),
      );

      expect(response.statusCode, 200);
      final decoded =
          jsonDecode(await response.readAsString()) as List<Object?>;
      expect(
        [for (final row in decoded) (row as Map<String, Object?>)['trace_id']],
        ['tr-2', 'tr-1'],
      );
    });

    test('honours a limit', () async {
      final api = routerOverStore();
      await api.store.record([
        queuedAt('tr-1', DateTime.utc(2026, 8, 18, 9, 30)),
        queuedAt('tr-2', DateTime.utc(2026, 8, 18, 9, 31)),
        queuedAt('tr-3', DateTime.utc(2026, 8, 18, 9, 32)),
      ]);

      final response = await api.handler(
        Request('GET', Uri.parse('http://localhost:8080/events?limit=2')),
      );

      expect(
        (jsonDecode(await response.readAsString()) as List<Object?>).length,
        2,
      );
    });

    test('answers 400 naming the limit it refused', () async {
      final api = routerOverStore();

      final response = await api.handler(
        Request('GET', Uri.parse('http://localhost:8080/events?limit=abc')),
      );

      expect(response.statusCode, 400);
      // The field, not merely the status: a 400 that does not say which parameter was
      // wrong leaves the caller guessing at four of them.
      final body =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;
      expect(body['field'], 'limit');
    });
  });

  group('unknown routes', () {
    test('answer 404 with the same error shape as everything else', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/nope')),
      );

      expect(response.statusCode, 404);
      expect(await bodyOf(response), contains('error'));
    });

    test('answer 404 for GET /send, which only accepts POST', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/send')),
      );

      expect(response.statusCode, 404);
    });
  });
}
