import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  late InMemoryTelemetryStore store;

  setUp(() => store = InMemoryTelemetryStore());

  // Built per request rather than once, because `store` is replaced by `setUp`
  // and a router captured earlier would hold the previous test's store.
  Handler handler() => ApiRouter(
    sender: FakeFcmSender(),
    now: () => DateTime.utc(2026, 8, 13, 9),
    newTraceId: () => 'tr-1',
    telemetry: store,
  ).handler;

  Future<Response> post(Object? body) async => handler()(
    Request(
      'POST',
      Uri.parse('http://localhost:8080/events'),
      body: body is String ? body : jsonEncode(body),
      headers: const {'content-type': 'application/json'},
    ),
  );

  Future<Response> get(String path) async =>
      handler()(Request('GET', Uri.parse('http://localhost:8080$path')));

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  Future<List<Object?>> rowsOf(Response response) async =>
      jsonDecode(await response.readAsString()) as List<Object?>;

  final sentAt = DateTime.utc(2026, 8, 13, 9, 30);
  final arrivedAt = DateTime.utc(2026, 8, 13, 9, 30, 0, 400);

  Map<String, Object?> arrivalJson(String trace, String device) => {
    'trace_id': trace,
    'type': 'received_fg',
    'at': arrivedAt.toIso8601String(),
    'device_id': device,
  };

  Map<String, Object?> sentJson(String trace) => {
    'trace_id': trace,
    'type': 'sent',
    'at': sentAt.toIso8601String(),
    'device_id': '',
  };

  // The plainest well-formed event, for the tests that are about the batch
  // rather than about any one event's contents.
  Map<String, Object?> eventJson(String trace) => arrivalJson(trace, 'dev-a');

  group('POST /events', () {
    test('records a batch and reports how many were new', () async {
      final response = await post({
        'events': [eventJson('tr-1'), eventJson('tr-2')],
      });

      expect(response.statusCode, 200);
      final body = await bodyOf(response);
      expect(body, equals(const {'recorded': 2}));
      expect(
        body['recorded'],
        isA<int>(),
        reason: '5.0 == 5 in Dart, so the type is asserted beside the value',
      );
      expect(
        await store.all(),
        hasLength(2),
        reason: 'the count must come from the store, not from the input length',
      );
    });

    test('counts only the new members of a partly replayed batch', () async {
      // The discriminator the first test cannot make: here the input list is
      // two long and the answer must be 1, so returning `events.length` fails.
      await post({
        'events': [eventJson('tr-1')],
      });

      final response = await post({
        'events': [eventJson('tr-1'), eventJson('tr-2')],
      });

      expect(response.statusCode, 200);
      final recorded = (await bodyOf(response))['recorded'];
      expect(recorded, 1);
      expect(recorded, isA<int>());
      expect(await store.all(), hasLength(2));
    });

    test('reports zero new on a replayed batch, without failing it', () async {
      // The retry path. A 4xx here would make a client that already succeeded
      // retry forever, and a silent 200 with no count would hide a lost flush.
      await post({
        'events': [eventJson('tr-1')],
      });

      final again = await post({
        'events': [eventJson('tr-1')],
      });

      expect(again.statusCode, 200);
      expect(await bodyOf(again), equals(const {'recorded': 0}));
      expect(await store.all(), hasLength(1));
    });

    test('accepts an empty batch, which is a flush of nothing', () async {
      final response = await post({'events': <Object?>[]});

      expect(response.statusCode, 200);
      expect(await bodyOf(response), equals(const {'recorded': 0}));
    });

    test('answers 400 for a malformed event, naming the problem', () async {
      final response = await post({
        'events': [
          {...eventJson('tr-1'), 'type': 'invented'},
        ],
      });

      expect(response.statusCode, 400);
      expect(
        (await bodyOf(response))['error'],
        contains('invented'),
        reason: 'the client has to be told which member it must fix',
      );
    });

    test('answers 400 for an event missing its trace', () async {
      final response = await post({
        'events': [
          {'type': 'received_fg'},
        ],
      });

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('trace_id'));
    });

    test('answers 400 when events is missing or not a list', () async {
      expect((await post(const <String, Object?>{})).statusCode, 400);
      expect((await post({'events': 'nope'})).statusCode, 400);
    });

    test('answers 400, not 500, when a member is not an object', () async {
      // A blind cast of the list would raise a TypeError here, which reaches
      // the client as a 500 and reads as a server fault rather than a bad body.
      final response = await post({
        'events': [1, 2],
      });

      expect(response.statusCode, 400);
      expect(await bodyOf(response), contains('error'));
    });

    test('answers 400 when the body is not JSON at all', () async {
      final response = await post('not json');

      expect(response.statusCode, 400);
    });

    test('accepts an event whose trace was never queued here', () async {
      // A curl send by hand produces no `queued` row. Refusing its arrival would
      // hide a real delivery, and the store has no foreign key for this reason.
      final response = await post({
        'events': [eventJson('never-seen')],
      });

      expect(response.statusCode, 200);
      expect(
        await store.all(),
        hasLength(1),
        reason:
            'a 200 that stored nothing would hide the delivery just as well',
      );
    });

    test('answers JSON', () async {
      final response = await post({
        'events': [eventJson('tr-1')],
      });

      expect(response.headers['content-type'], startsWith('application/json'));
    });

    test('a batch is all-or-nothing on a malformed member', () async {
      // Half-storing a batch would leave the client unable to say what to retry.
      // The two good members are a complete latency pair, so a partial store
      // shows up in both assertions below rather than only in the store.
      final response = await post({
        'events': [
          sentJson('tr-good'),
          arrivalJson('tr-good', 'dev-a'),
          {'type': 'invented'},
        ],
      });

      expect(response.statusCode, 400);
      expect(
        await store.all(),
        isEmpty,
        reason: 'nothing at all may be stored, whatever /latency then shows',
      );
      expect(await rowsOf(await get('/latency')), isEmpty);
    });
  });

  group('GET /latency', () {
    test('returns one row per trace and device', () async {
      await post({
        'events': [sentJson('tr-1'), arrivalJson('tr-1', 'dev-a')],
      });

      final response = await get('/latency');

      expect(response.statusCode, 200);
      final rows = await rowsOf(response);
      expect(rows, hasLength(1));
      final row = rows.single;
      final expected = {
        'trace_id': 'tr-1',
        'device_id': 'dev-a',
        'sent_at': sentAt.toIso8601String(),
        'received_at': arrivedAt.toIso8601String(),
      };
      expect(
        row,
        equals(expected),
        reason: 'the wire shape is LatencyRow.toJson, not a second spelling',
      );
    });

    test('returns a row per device for one send to two handsets', () async {
      await post({
        'events': [
          sentJson('tr-1'),
          arrivalJson('tr-1', 'dev-a'),
          arrivalJson('tr-1', 'dev-b'),
        ],
      });

      final rows = await rowsOf(await get('/latency'));

      expect(rows, hasLength(2));
      final devices = [
        for (final row in rows) (row as Map<String, Object?>)['device_id'],
      ];
      expect(devices, containsAll(const ['dev-a', 'dev-b']));
    });

    test('answers an empty list rather than 404 when nothing paired', () async {
      // A send with no arrival is the interesting case this pipeline exists for,
      // and it must read as "no measurements yet" rather than as an error.
      await post({
        'events': [sentJson('tr-1')],
      });

      final response = await get('/latency');

      expect(response.statusCode, 200);
      expect(await rowsOf(response), isEmpty);
      expect(response.headers['content-type'], startsWith('application/json'));
    });
  });
}
