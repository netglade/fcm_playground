import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SendMessageRequest', () {
    const request = SendMessageRequest(
      target: TokenTarget('device-token'),
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

      expect(parsed.target, const TokenTarget('device-token'));
      expect(parsed.validateOnly, isFalse);
      expect(parsed.message.notification?.title, 'Hi');
    });

    test('carries the scenario id, which nothing else can recover', () {
      // The payload a scenario produces does not identify the scenario, so without
      // the sender naming it the matrix has no scenario axis.
      const request = SendMessageRequest(
        target: TokenTarget('abc'),
        message: FcmMessage(),
        scenarioId: 'a1_notification_only',
      );

      expect(request.toJson()['scenario_id'], 'a1_notification_only');
      expect(
        SendMessageRequest.fromJson(request.toJson()).scenarioId,
        'a1_notification_only',
      );
    });

    test('omits the scenario id for a payload composed by hand', () {
      // Absent rather than empty: an empty string would become a matrix row for a
      // scenario that does not exist.
      const request = SendMessageRequest(
        target: TokenTarget('abc'),
        message: FcmMessage(),
      );

      expect(request.toJson().containsKey('scenario_id'), isFalse);
      expect(SendMessageRequest.fromJson(request.toJson()).scenarioId, isNull);
    });

    test('reads a topic target', () {
      final request = SendMessageRequest.fromJson({
        'topic': 'news',
        'message': {
          'notification': {'title': 'Hi'},
        },
      });

      expect(request.target, const TopicTarget('news'));
    });

    test('writes the target back at the top level', () {
      const request = SendMessageRequest(
        target: TopicTarget('news'),
        message: FcmMessage(),
      );

      expect(request.toJson()['topic'], 'news');
      expect(request.toJson().containsKey('token'), isFalse);
    });

    test('carries validate_only when set', () {
      const validating = SendMessageRequest(
        target: TokenTarget('t'),
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

    test('still rejects a message that sets a target of another kind', () {
      // The envelope owning the target is exactly why the message must not.
      expect(
        () => SendMessageRequest.fromJson({
          'token': 'abc',
          'message': {'topic': 'news'},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SendMessageResponse', () {
    final response = SendMessageResponse(
      messageId: 'projects/p/messages/0:17',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
      traceId: 'tr-1',
    );

    test('round-trips', () {
      final parsed = SendMessageResponse.fromJson(response.toJson());

      expect(parsed.messageId, response.messageId);
      expect(parsed.sentAt, response.sentAt);
      expect(parsed.traceId, response.traceId);
    });

    test('writes exactly the three fields the caller needs', () {
      // Pinned as a whole map: a fourth key, or traceId written as `trace_id`, would
      // be a silent contract change for the app parsing this.
      expect(response.toJson(), {
        'messageId': 'projects/p/messages/0:17',
        'sentAt': '2026-08-11T09:12:03.000Z',
        'traceId': 'tr-1',
      });
    });

    test('normalises the timestamp to UTC', () {
      final parsed = SendMessageResponse.fromJson({
        'messageId': 'm',
        'sentAt': '2026-08-11T11:12:03+02:00',
        'traceId': 'tr-1',
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

    test('rejects a response with no trace id, rather than blanking it', () {
      // An absent trace id means an older server, and a blank one would look like a
      // send that never got correlated.
      expect(
        () => SendMessageResponse.fromJson({
          'messageId': 'm',
          'sentAt': '2026-08-11T09:12:03.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
