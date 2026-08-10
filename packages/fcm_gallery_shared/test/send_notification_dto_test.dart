import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _request = SendNotificationRequest(
  token: 'device-token',
  draft: NotificationDraft(
    event: NotificationEvent.buildFinished,
    title: 'Build finished',
    body: 'Release 1.0.0 is ready.',
  ),
);

final _response = SendNotificationResponse(
  messageId: 'projects/fcm-sandbox-770fa/messages/1',
  payloadId: 'sandbox-1754812800000000',
  sentAt: DateTime.utc(2026, 8, 10, 9, 30),
);

void main() {
  group('SendNotificationRequest', () {
    test('round-trips through JSON', () {
      expect(SendNotificationRequest.fromJson(_request.toJson()), _request);
    });

    test('a missing token is a format error', () {
      final json = _request.toJson()..remove('token');

      expect(
        () => SendNotificationRequest.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('SendNotificationResponse', () {
    test('round-trips through JSON', () {
      expect(SendNotificationResponse.fromJson(_response.toJson()), _response);
    });

    test('sentAt is serialised as an ISO-8601 UTC string', () {
      expect(_response.toJson()['sentAt'], '2026-08-10T09:30:00.000Z');
    });

    test('sentAt is normalised to UTC on the way in', () {
      final local = SendNotificationResponse(
        messageId: 'm',
        payloadId: 'p',
        sentAt: DateTime.utc(2026, 8, 10).toLocal(),
      );

      expect(local.sentAt.isUtc, isTrue);
    });

    test('jsonEncode works on the object itself', () {
      // This is exactly what firebase_functions does with the returned value:
      // jsonEncode({'result': response}), which reaches toJson via toEncodable.
      final encoded = jsonEncode({'result': _response});

      expect(encoded, contains('sandbox-1754812800000000'));
    });

    test('an unparseable sentAt is a format error', () {
      final json = _response.toJson()..['sentAt'] = 'yesterday';

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });

    test('a missing messageId is a format error, not the string "null"', () {
      final json = _response.toJson()..remove('messageId');

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });

    test('a missing payloadId is a format error, not the string "null"', () {
      final json = _response.toJson()..remove('payloadId');

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });
  });
}
