import 'dart:convert';
import 'dart:io';

import 'package:fcm_app/sandbox/http_notification_sender.dart';
import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/unavailable_notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  HttpNotificationSender senderAnswering(int statusCode, Object? body) =>
      HttpNotificationSender(
        client: MockClient((request) async {
          requests.add(request);

          return http.Response(jsonEncode(body), statusCode);
        }),
        baseUrl: Uri.parse('http://localhost:8080'),
      );

  const request = SendMessageRequest(
    token: 'device-token',
    message: FcmMessage(
      notification: FcmNotification(
        title: 'Build finished',
        body: 'main #128 passed',
      ),
    ),
  );

  final successBody = {
    'messageId': 'projects/p/messages/0:17',
    'sentAt': '2026-08-11T09:12:03.000Z',
  };

  setUp(() {
    requests = [];
  });

  group('HttpNotificationSender.send', () {
    test('posts the token, validate_only flag and message to /send', () async {
      await senderAnswering(200, successBody).send(request);

      expect(requests.single.url.path, '/send');
      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body), {
        'token': 'device-token',
        'validate_only': false,
        'message': {
          'notification': {
            'title': 'Build finished',
            'body': 'main #128 passed',
          },
        },
      });
    });

    test('returns the parsed response', () async {
      final response = await senderAnswering(200, successBody).send(request);

      expect(response.messageId, 'projects/p/messages/0:17');
      expect(response.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
    });

    test('surfaces the server\'s error message and field', () async {
      final sender = senderAnswering(400, {
        'error': 'title must not be blank',
        'field': 'title',
      });

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>()
              .having(
                (error) => error.message,
                'message',
                'title must not be blank',
              )
              .having((error) => error.field, 'field', 'title'),
        ),
      );
    });

    test(
      'stays readable when the error body is not the documented shape',
      () async {
        final sender = senderAnswering(502, 'Bad Gateway');

        await expectLater(
          () => sender.send(request),
          throwsA(
            isA<NotificationSendException>().having(
              (error) => error.message,
              'message',
              contains('502'),
            ),
          ),
        );
      },
    );

    test(
      'names the base URL and adb reverse when nothing is listening',
      () async {
        final sender = HttpNotificationSender(
          client: MockClient(
            (request) async =>
                throw const SocketException('connection refused'),
          ),
          baseUrl: Uri.parse('http://localhost:8080'),
        );

        await expectLater(
          () => sender.send(request),
          throwsA(
            isA<NotificationSendException>()
                .having(
                  (error) => error.message,
                  'message',
                  contains('http://localhost:8080'),
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('adb reverse'),
                ),
          ),
        );
      },
    );

    test('rejects a 200 body it cannot read', () async {
      final sender = senderAnswering(200, {'messageId': 'm'});

      await expectLater(
        () => sender.send(request),
        throwsA(isA<NotificationSendException>()),
      );
    });
  });

  group('UnavailableNotificationSender', () {
    test('always fails with the reason it was given', () async {
      const sender = UnavailableNotificationSender('Firebase did not start');

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>().having(
            (error) => error.message,
            'message',
            'Firebase did not start',
          ),
        ),
      );
    });
  });
}
