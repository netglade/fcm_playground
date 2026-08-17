import 'dart:convert';

import 'package:fcm_app/domains/runs/data_sources/http_run_scheduler.dart';
import 'package:fcm_app/domains/runs/data_sources/unavailable_run_scheduler.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fakes/socket_exception_stub.dart';

void main() {
  late List<http.Request> requests;

  HttpRunScheduler schedulerAnswering(int statusCode, Object? body) =>
      HttpRunScheduler(
        client: MockClient((request) async {
          requests.add(request);

          return http.Response(jsonEncode(body), statusCode);
        }),
        baseUrl: Uri.parse('http://localhost:8080'),
      );

  const request = ScheduleRunRequest(
    delaySeconds: 30,
    items: [
      SendMessageRequest(
        target: TokenTarget('device-token'),
        message: FcmMessage(),
        scenarioId: 'b3_killed',
      ),
    ],
  );

  final runBody = {
    'run_id': 'run-1',
    'created_at': '2026-08-17T09:00:00.000Z',
    'items': [
      {
        'index': 0,
        'request': {
          'token': 'device-token',
          'validate_only': false,
          'message': <String, Object?>{},
        },
        'due_at': '2026-08-17T09:00:30.000Z',
        'state': 'pending',
      },
    ],
  };

  setUp(() => requests = []);

  group('schedule', () {
    test('posts the whole request to /runs', () async {
      await schedulerAnswering(201, runBody).schedule(request);

      expect(requests.single.url.path, '/runs');
      expect(requests.single.method, 'POST');
      expect(
        jsonDecode(requests.single.body),
        containsPair('delay_seconds', 30),
      );
    });

    test('reads the run back', () async {
      final run = await schedulerAnswering(201, runBody).schedule(request);

      expect(run.id, 'run-1');
      expect(run.items.single.state, RunItemState.pending);
    });

    test('reports the server\'s own error message', () async {
      expect(
        () => schedulerAnswering(400, {
          'error': 'items[0]: "titel" is unknown',
        }).schedule(request),
        throwsA(
          isA<RunSchedulerException>().having(
            (e) => e.message,
            'message',
            contains('titel'),
          ),
        ),
      );
    });

    test('names the port forward when the API cannot be reached', () async {
      final scheduler = HttpRunScheduler(
        client: MockClient((_) => throw const SocketExceptionStub()),
        baseUrl: Uri.parse('http://localhost:8080'),
      );

      expect(
        scheduler.schedule(request),
        throwsA(
          isA<RunSchedulerException>().having(
            (e) => e.message,
            'message',
            contains('adb reverse'),
          ),
        ),
      );
    });
  });

  group('list, fetch and cancel', () {
    test('gets the summaries from /runs', () async {
      final summaries = await schedulerAnswering(200, [
        {
          'run_id': 'run-1',
          'created_at': '2026-08-17T09:00:00.000Z',
          'item_count': 2,
          'states': {'pending': 2},
        },
      ]).list();

      expect(requests.single.url.path, '/runs');
      expect(summaries.single.itemCount, 2);
    });

    test('gets one run from /runs/<id>', () async {
      final run = await schedulerAnswering(200, runBody).fetch('run-1');

      expect(requests.single.url.path, '/runs/run-1');
      expect(run.id, 'run-1');
    });

    test('deletes /runs/<id> and reads the count back', () async {
      final cancelled = await schedulerAnswering(200, {
        'cancelled': 2,
      }).cancel('run-1');

      expect(requests.single.method, 'DELETE');
      expect(cancelled, 2);
    });

    test('reports a 404 as a failure the user can read', () async {
      expect(
        () => schedulerAnswering(404, {
          'error': 'There is no run "x".',
        }).fetch('x'),
        throwsA(isA<RunSchedulerException>()),
      );
    });
  });

  test('UnavailableRunScheduler fails every call with its reason', () async {
    const scheduler = UnavailableRunScheduler('Firebase never started');

    expect(
      scheduler.list(),
      throwsA(
        isA<RunSchedulerException>().having(
          (e) => e.message,
          'message',
          'Firebase never started',
        ),
      ),
    );
  });
}
