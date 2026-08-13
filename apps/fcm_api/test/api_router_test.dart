import 'dart:async';
import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Handler handlerWith(FakeFcmSender sender) =>
      ApiRouter(sender: sender, now: () => sentAt).handler;

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
    test('answers 200 with the stamped id and timestamp', () async {
      final response = await post(validBody());

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {
        'messageId': 'projects/p/messages/0:17',
        'sentAt': '2026-08-11T09:12:03.000Z',
      });
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
