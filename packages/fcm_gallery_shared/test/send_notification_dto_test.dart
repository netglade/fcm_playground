import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SendNotificationRequest', () {
    const request = SendNotificationRequest(
      token: 'device-token',
      draft: NotificationDraft(
        title: 'Build finished',
        body: 'main #128 passed',
        data: {'event': 'build_finished'},
      ),
    );

    test('serialises flat, so the DTO is the endpoint body', () {
      expect(request.toJson(), {
        'token': 'device-token',
        'title': 'Build finished',
        'body': 'main #128 passed',
        'data': {'event': 'build_finished'},
      });
    });

    test('round-trips', () {
      final parsed = SendNotificationRequest.fromJson(request.toJson());

      expect(parsed.token, request.token);
      expect(parsed.draft, request.draft);
    });

    test('treats an absent token as blank, for the server to name', () {
      final parsed = SendNotificationRequest.fromJson({
        'title': 'Hi',
        'body': 'There',
      });

      expect(parsed.token, isEmpty);
    });

    test('rejects a non-string token', () {
      expect(
        () => SendNotificationRequest.fromJson({'token': 7}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SendNotificationResponse', () {
    final response = SendNotificationResponse(
      messageId: 'projects/p/messages/0:17',
      payloadId: 'api-1754812345678901',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    );

    test('writes the payload id under the wire key "id"', () {
      expect(response.toJson(), {
        'messageId': 'projects/p/messages/0:17',
        'id': 'api-1754812345678901',
        'sentAt': '2026-08-11T09:12:03.000Z',
      });
    });

    test('round-trips', () {
      final parsed = SendNotificationResponse.fromJson(response.toJson());

      expect(parsed.messageId, response.messageId);
      expect(parsed.payloadId, response.payloadId);
      expect(parsed.sentAt, response.sentAt);
    });

    test('normalises the timestamp to UTC', () {
      final parsed = SendNotificationResponse.fromJson({
        'messageId': 'm',
        'id': 'p',
        'sentAt': '2026-08-11T11:12:03+02:00',
      });

      expect(parsed.sentAt.isUtc, isTrue);
      expect(parsed.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
    });

    test('rejects a response missing a field, rather than inventing one', () {
      expect(
        () => SendNotificationResponse.fromJson({'messageId': 'm', 'id': 'p'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unparseable timestamp', () {
      expect(
        () => SendNotificationResponse.fromJson({
          'messageId': 'm',
          'id': 'p',
          'sentAt': 'yesterday',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ApiError', () {
    test('omits the field key when there is no field to blame', () {
      expect(const ApiError('FCM is unreachable').toJson(), {
        'error': 'FCM is unreachable',
      });
    });

    test('round-trips with a field', () {
      const error = ApiError('title must not be blank', field: 'title');

      final parsed = ApiError.fromJson(error.toJson());

      expect(parsed.message, error.message);
      expect(parsed.field, 'title');
    });

    test('tolerates a non-string field rather than failing the error path', () {
      final parsed = ApiError.fromJson({'error': 'boom', 'field': 7});

      expect(parsed.field, isNull);
    });

    test('rejects a body with no error message', () {
      expect(
        () => ApiError.fromJson({'field': 'title'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
