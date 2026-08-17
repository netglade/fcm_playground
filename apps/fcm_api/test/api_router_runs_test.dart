import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 9, 0);

  late InMemoryRunStore runs;
  late InMemoryTelemetryStore telemetry;
  late FakeFcmSender sender;
  late SendScheduler scheduler;
  late Handler handler;
  late int minted;

  setUp(() {
    runs = InMemoryRunStore();
    telemetry = InMemoryTelemetryStore();
    sender = FakeFcmSender();
    minted = 0;
    scheduler = SendScheduler(
      runs: runs,
      telemetry: telemetry,
      sender: sender,
      newId: () => 'id-${++minted}',
      now: () => now,
    );
    handler = ApiRouter(
      sender: sender,
      now: () => now,
      newTraceId: () => 'tr-1',
      telemetry: telemetry,
      scheduler: scheduler,
    ).handler;
  });

  Future<Response> post(Object? body) => Future.value(
    handler(
      Request(
        'POST',
        Uri.parse('http://localhost:8080/runs'),
        body: jsonEncode(body),
        headers: const {'content-type': 'application/json'},
      ),
    ),
  );

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  Map<String, Object?> item({Object? token = 'device-token'}) => {
    'token': ?token,
    'scenario_id': 'b3_killed',
    'message': {
      'data': {'event': 'killed_probe'},
    },
  };

  test('answers 201 with the run and the times it computed', () async {
    final response = await post({
      'delay_seconds': 30,
      'spacing_seconds': 5,
      'items': [item(), item()],
    });

    expect(response.statusCode, 201);
    final body = await bodyOf(response);
    expect(body['run_id'], 'id-1');
    final items = body['items']! as List<Object?>;
    expect(items, hasLength(2));
    expect(
      (items.first! as Map<String, Object?>)['due_at'],
      '2026-08-17T09:00:30.000Z',
    );
    expect(
      (items.last! as Map<String, Object?>)['due_at'],
      '2026-08-17T09:00:35.000Z',
    );
  });

  test('stores the run, so it is there to dispatch', () async {
    await post({
      'delay_seconds': 0,
      'items': [item()],
    });

    expect((await runs.find('id-1'))?.items, hasLength(1));
  });

  test('sends nothing at scheduling time', () async {
    await post({
      'delay_seconds': 0,
      'items': [item()],
    });

    expect(sender.sent, isEmpty);
  });

  test('answers 400 naming the item and the field at fault', () async {
    final response = await post({
      'delay_seconds': 30,
      'items': [
        item(),
        {
          'token': 'device-token',
          'message': {
            'notification': {'titel': 'typo'},
          },
        },
      ],
    });

    expect(response.statusCode, 400);
    expect(
      (await bodyOf(response))['error'],
      allOf(contains('items[1]'), contains('titel')),
    );
  });

  test('answers 400 for a delay that is not a number of seconds', () async {
    final response = await post({
      'delay_seconds': 'soon',
      'items': [item()],
    });

    expect(response.statusCode, 400);
  });

  test('answers 400 for an empty item list', () async {
    final response = await post({'delay_seconds': 30, 'items': <Object?>[]});

    expect(response.statusCode, 400);
  });

  test('refuses every device with 501, before anything is stored', () async {
    final response = await post({
      'delay_seconds': 30,
      'items': [
        {
          'all_devices': true,
          'message': {
            'data': {'event': 'killed_probe'},
          },
        },
      ],
    });

    expect(response.statusCode, 501);
    expect((await bodyOf(response))['field'], 'all_devices');
    expect(await runs.recent(), isEmpty);
  });

  Future<Response> get(String path) => Future.value(
    handler(Request('GET', Uri.parse('http://localhost:8080$path'))),
  );

  Future<Response> delete(String path) => Future.value(
    handler(Request('DELETE', Uri.parse('http://localhost:8080$path'))),
  );

  Future<List<Object?>> listOf(Response response) async =>
      jsonDecode(await response.readAsString()) as List<Object?>;

  group('GET /runs', () {
    test('answers an empty list before anything is scheduled', () async {
      expect(await listOf(await get('/runs')), isEmpty);
    });

    test('summarises each run without carrying its messages', () async {
      await post({
        'delay_seconds': 30,
        'items': [item(), item()],
      });

      final rows = await listOf(await get('/runs'));
      final row = rows.single! as Map<String, Object?>;
      expect(row['run_id'], 'id-1');
      expect(row['item_count'], 2);
      expect(row['states'], {'pending': 2});
      expect(row['next_due_at'], '2026-08-17T09:00:30.000Z');
      expect(row, isNot(contains('items')));
    });
  });

  group('GET /runs/<id>', () {
    test('answers 404 for a run that does not exist', () async {
      expect((await get('/runs/nope')).statusCode, 404);
    });

    test('carries each item\'s telemetry, which is the timeline', () async {
      await post({
        'delay_seconds': 0,
        'items': [item()],
      });
      await scheduler.tick(now);

      final body = await bodyOf(await get('/runs/id-1'));
      final items = body['items']! as List<Object?>;
      final only = items.single! as Map<String, Object?>;
      expect(only['state'], 'sent');
      expect(
        (only['events']! as List<Object?>).map(
          (e) => (e! as Map<String, Object?>)['type'],
        ),
        ['queued', 'sent'],
      );
    });

    test('carries an empty timeline as no events at all', () async {
      await post({
        'delay_seconds': 30,
        'items': [item()],
      });

      final body = await bodyOf(await get('/runs/id-1'));
      final only =
          (body['items']! as List<Object?>).single! as Map<String, Object?>;
      expect(only, isNot(contains('events')));
    });
  });

  group('DELETE /runs/<id>', () {
    test('cancels what is pending and reports the count', () async {
      await post({
        'delay_seconds': 30,
        'spacing_seconds': 30,
        'items': [item(), item()],
      });

      final response = await delete('/runs/id-1');

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {'cancelled': 2});
    });

    test('answers 404 for a run that does not exist', () async {
      expect((await delete('/runs/nope')).statusCode, 404);
    });

    test(
      'reports zero rather than failing when it is already too late',
      () async {
        await post({
          'delay_seconds': 0,
          'items': [item()],
        });
        await scheduler.tick(now);

        final response = await delete('/runs/id-1');

        expect(response.statusCode, 200);
        expect(await bodyOf(response), {'cancelled': 0});
      },
    );

    test('a cancelled run never sends', () async {
      await post({
        'delay_seconds': 30,
        'items': [item()],
      });
      await delete('/runs/id-1');

      await scheduler.tick(now.add(const Duration(minutes: 1)));

      expect(sender.sent, isEmpty);
    });
  });
}
