import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late List<http.Request> requests;

  MockClient clientAnswering(int statusCode, Object? body) =>
      MockClient((request) async {
        requests.add(request);

        return http.Response(
          jsonEncode(body),
          statusCode,
          headers: const {'content-type': 'application/json'},
        );
      });

  HttpV1FcmSender senderWith(http.Client client) =>
      HttpV1FcmSender(client: client, projectId: 'fcm-sandbox-770fa');

  Map<String, Object?> fcmError({
    required String status,
    String message = 'Something went wrong.',
    String? errorCode,
  }) => {
    'error': {
      'code': 400,
      'message': message,
      'status': status,
      if (errorCode != null)
        'details': [
          {
            '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
            'errorCode': errorCode,
          },
        ],
    },
  };

  setUp(() {
    requests = [];
  });

  group('HttpV1FcmSender.send', () {
    test('posts to the project\'s messages:send endpoint', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      await sender.send(const {'message': <String, Object?>{}});

      expect(
        requests.single.url.toString(),
        'https://fcm.googleapis.com/v1/projects/fcm-sandbox-770fa/messages:send',
      );
      expect(requests.single.method, 'POST');
    });

    test('sends the message as the JSON body', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      await sender.send(const {
        'message': {'token': 'device-token'},
      });

      expect(jsonDecode(requests.single.body), {
        'message': {'token': 'device-token'},
      });
    });

    test('returns the message name FCM assigned', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      expect(
        await sender.send(const {'message': <String, Object?>{}}),
        'projects/p/messages/0:17',
      );
    });

    test('prefers the FcmError detail over the generic status', () async {
      final sender = senderWith(
        clientAnswering(
          404,
          fcmError(
            status: 'NOT_FOUND',
            message: 'Requested entity was not found.',
            errorCode: 'UNREGISTERED',
          ),
        ),
      );

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>()
              .having((error) => error.status, 'status', 'UNREGISTERED')
              .having(
                (error) => error.message,
                'message',
                'Requested entity was not found.',
              ),
        ),
      );
    });

    test('falls back to the generic status when there is no detail', () async {
      final sender = senderWith(
        clientAnswering(429, fcmError(status: 'RESOURCE_EXHAUSTED')),
      );

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>().having(
            (error) => error.status,
            'status',
            'RESOURCE_EXHAUSTED',
          ),
        ),
      );
    });

    test('survives an error body that is not the documented shape', () async {
      final sender = senderWith(clientAnswering(500, 'gateway exploded'));

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>()
              .having((error) => error.status, 'status', 'UNKNOWN')
              .having(
                (error) => error.message,
                'message',
                contains('gateway exploded'),
              ),
        ),
      );
    });

    test(
      'treats a 200 without a name as a failure, not a silent success',
      () async {
        final sender = senderWith(
          clientAnswering(200, const <String, Object?>{}),
        );

        await expectLater(
          () => sender.send(const {'message': <String, Object?>{}}),
          throwsA(isA<FcmSendException>()),
        );
      },
    );
  });
}
