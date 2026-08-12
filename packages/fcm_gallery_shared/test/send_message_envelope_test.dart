import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SendMessageRequest', () {
    const request = SendMessageRequest(
      token: 'device-token',
      message: FcmMessage(notification: FcmNotification(title: 'Hi')),
    );

    test('writes the token, the flag and the message', () {
      expect(request.toJson(), {
        'token': 'device-token',
        'validate_only': false,
        'message': {
          'notification': {'title': 'Hi'},
        },
      });
    });

    test('round-trips', () {
      final parsed = SendMessageRequest.fromJson(request.toJson());

      expect(parsed.token, 'device-token');
      expect(parsed.validateOnly, isFalse);
      expect(parsed.message.notification?.title, 'Hi');
    });

    test('carries validate_only when set', () {
      const validating = SendMessageRequest(
        token: 't',
        message: FcmMessage(),
        validateOnly: true,
      );

      expect(validating.toJson()['validate_only'], isTrue);
      expect(
        SendMessageRequest.fromJson(validating.toJson()).validateOnly,
        isTrue,
      );
    });

    test('defaults validate_only to false when absent from the body', () {
      final parsed = SendMessageRequest.fromJson({
        'token': 't',
        'message': <String, Object?>{},
      });

      expect(parsed.validateOnly, isFalse);
    });

    test('rejects a body with no message, since there is nothing to send', () {
      expect(
        () => SendMessageRequest.fromJson({'token': 't'}),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'reports a malformed message with its path, not as a bare failure',
      () {
        expect(
          () => SendMessageRequest.fromJson({
            'token': 't',
            'message': {
              'notification': {'titel': 'typo'},
            },
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('notification: unknown field "titel"'),
            ),
          ),
        );
      },
    );

    test('rejects a message that sets its own target', () {
      expect(
        () => SendMessageRequest.fromJson({
          'token': 't',
          'message': {'token': 'other'},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('the server sets the delivery target'),
          ),
        ),
      );
    });
  });

  group('SendMessageResponse', () {
    final response = SendMessageResponse(
      messageId: 'projects/p/messages/0:17',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    );

    test('round-trips', () {
      final parsed = SendMessageResponse.fromJson(response.toJson());

      expect(parsed.messageId, response.messageId);
      expect(parsed.sentAt, response.sentAt);
    });

    test('normalises the timestamp to UTC', () {
      final parsed = SendMessageResponse.fromJson({
        'messageId': 'm',
        'sentAt': '2026-08-11T11:12:03+02:00',
      });

      expect(parsed.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
      expect(parsed.sentAt.isUtc, isTrue);
    });

    test('rejects a response missing a field rather than inventing one', () {
      expect(
        () => SendMessageResponse.fromJson({'messageId': 'm'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
