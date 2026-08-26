import 'dart:convert';

import 'package:fcm_app/domains/telemetry/http_telemetry_reader.dart';
import 'package:fcm_app/domains/telemetry/telemetry_reader_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fakes/socket_exception_stub.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8080');

  HttpTelemetryReader readerAnswering(
    Future<http.Response> Function(http.Request request) answer,
  ) => HttpTelemetryReader(client: MockClient(answer), baseUrl: baseUrl);

  group('HttpTelemetryReader.recentEvents', () {
    test('asks GET /events for the limit it was given', () async {
      Uri? asked;
      final reader = readerAnswering((request) async {
        asked = request.url;

        return http.Response('[]', 200);
      });

      await reader.recentEvents(limit: 25);

      // The path and the parameter: a reader that dropped the limit would return the
      // server's default and no assertion about the list would notice.
      expect(asked?.path, '/events');
      expect(asked?.queryParameters['limit'], '25');
    });

    test('parses the events the API answered with', () async {
      final event = TelemetryEvent(
        traceId: 't1',
        type: TelemetryEventType.opened,
        at: DateTime.utc(2026, 8, 18, 9, 30),
        deviceId: 'd1',
        detail: 'background',
      );
      final reader = readerAnswering(
        (_) async => http.Response(jsonEncode([event.toJson()]), 200),
      );

      final events = await reader.recentEvents();

      expect(events.single.traceId, 't1');
      expect(events.single.type, TelemetryEventType.opened);
      expect(events.single.detail, 'background');
    });

    test('turns a dead socket into a message naming the remedy', () async {
      final reader = readerAnswering(
        (_) async => throw const SocketExceptionStub(),
      );

      // The usual cause is a forgotten port forward, so the remedy belongs in the
      // message rather than in the exception type.
      await expectLater(
        reader.recentEvents(),
        throwsA(
          isA<TelemetryReaderException>().having(
            (error) => error.message,
            'message',
            contains('adb reverse'),
          ),
        ),
      );
    });

    test('reports the API error a non-200 carried', () async {
      final reader = readerAnswering(
        (_) async => http.Response(
          jsonEncode(
            const ApiError('limit was rubbish', field: 'limit').toJson(),
          ),
          400,
        ),
      );

      await expectLater(
        reader.recentEvents(),
        throwsA(
          isA<TelemetryReaderException>().having(
            (error) => error.message,
            'message',
            'limit was rubbish',
          ),
        ),
      );
    });

    test('turns a 200 that is not JSON into a readable message', () async {
      final reader = readerAnswering(
        (_) async => http.Response('not json at all', 200),
      );

      // Not merely the type: a message a raw FormatException would never have
      // produced is the point of the guard.
      await expectLater(
        reader.recentEvents(),
        throwsA(
          isA<TelemetryReaderException>().having(
            (error) => error.message,
            'message',
            contains('not JSON'),
          ),
        ),
      );
    });

    test('turns a row missing trace_id into a readable message', () async {
      final reader = readerAnswering(
        (_) async => http.Response(
          jsonEncode([
            {'type': 'opened', 'at': '2026-08-18T09:30:00Z', 'device_id': 'd1'},
          ]),
          200,
        ),
      );

      await expectLater(
        reader.recentEvents(),
        throwsA(
          isA<TelemetryReaderException>().having(
            (error) => error.message,
            'message',
            allOf(contains('an event'), contains('trace_id')),
          ),
        ),
      );
    });
  });

  group('HttpTelemetryReader.latencies', () {
    test('parses the rows GET /latency answered with', () async {
      final row = LatencyRow(
        traceId: 't1',
        deviceId: 'd1',
        sentAt: DateTime.utc(2026, 8, 18, 9, 30),
        receivedAt: DateTime.utc(2026, 8, 18, 9, 30, 0, 300),
        scenarioId: 'a1_notification_only',
      );
      final reader = readerAnswering(
        (_) async => http.Response(jsonEncode([row.toJson()]), 200),
      );

      final rows = await reader.latencies();

      expect(rows.single.traceId, 't1');
      expect(rows.single.latency, const Duration(milliseconds: 300));
    });

    test('turns a row missing sent_at into a readable message', () async {
      final reader = readerAnswering(
        (_) async => http.Response(
          jsonEncode([
            {
              'trace_id': 't1',
              'device_id': 'd1',
              'received_at': '2026-08-18T09:30:00Z',
            },
          ]),
          200,
        ),
      );

      await expectLater(
        reader.latencies(),
        throwsA(
          isA<TelemetryReaderException>().having(
            (error) => error.message,
            'message',
            allOf(contains('a latency row'), contains('sent_at')),
          ),
        ),
      );
    });
  });
}
