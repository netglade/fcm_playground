import 'package:fcm_functions/send_notification_handler.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

import 'fake_fcm_message_sender.dart';

const _draft = NotificationDraft(
  event: NotificationEvent.promo,
  title: 'Sale',
  body: 'Half price.',
);

const _request = SendNotificationRequest(token: 'device-token', draft: _draft);

final _requestJson = _request.toJson();

final _now = DateTime.utc(2026, 8, 10, 9, 30);

/// Extracted so `test(...)` fits on one line. Inlined, the literal wraps onto
/// a second line and `dart format` keeps the trailing closure hugging the
/// call, which `dcm`'s trailing-comma rule then flags — this sidesteps that
/// clash instead of fighting either tool.
const _payloadMatchesResponseDescription =
    'the payload it sent carries the id it reported, so the app can match '
    'the response against the inbox';

Future<SendNotificationResponse> _handle(
  FakeFcmMessageSender sender, {
  Map<String, dynamic>? json,
}) => handleSendNotification(
  json ?? _requestJson,
  sender: sender,
  newPayloadId: () => 'sandbox-1',
  now: () => _now,
);

void main() {
  group('handleSendNotification', () {
    test('reports the message id, payload id and timestamp it used', () async {
      final sender = FakeFcmMessageSender();

      final response = await _handle(sender);

      expect(response.messageId, 'projects/fcm-sandbox-770fa/messages/42');
      expect(response.payloadId, 'sandbox-1');
      expect(response.sentAt, _now);
    });

    test(_payloadMatchesResponseDescription, () async {
      final sender = FakeFcmMessageSender();

      final response = await _handle(sender);

      expect(sender.sentMessage?.data?['id'], response.payloadId);
    });

    test(
      'rejects a draft the shared validator refuses, naming the field',
      () async {
        final sender = FakeFcmMessageSender();
        final invalid = const SendNotificationRequest(
          token: 'device-token',
          draft: NotificationDraft(
            event: NotificationEvent.promo,
            title: '',
            body: '',
          ),
        ).toJson();

        await expectLater(
          _handle(sender, json: invalid),
          throwsA(
            isA<InvalidArgumentError>().having(
              (e) => e.message,
              'message',
              allOf(contains('title'), contains('body')),
            ),
          ),
        );
        expect(sender.sentMessage, isNull, reason: 'nothing should be sent');
      },
    );

    test('rejects a blank token', () async {
      final sender = FakeFcmMessageSender();
      final blank = const SendNotificationRequest(
        token: '   ',
        draft: _draft,
      ).toJson();

      await expectLater(
        _handle(sender, json: blank),
        throwsA(isA<InvalidArgumentError>()),
      );
      expect(sender.sentMessage, isNull);
    });

    test(
      'turns an unregistered token into an explanation, not a raw code',
      () async {
        final sender = FakeFcmMessageSender()
          ..failWith = FirebaseMessagingAdminException(
            MessagingClientErrorCode.registrationTokenNotRegistered,
          );

        await expectLater(
          _handle(sender),
          throwsA(
            isA<InvalidArgumentError>().having(
              (e) => e.message,
              'message',
              contains('no longer registered'),
            ),
          ),
        );
      },
    );

    test('names the FCM error code for cases it has no wording for', () async {
      final sender = FakeFcmMessageSender()
        ..failWith = FirebaseMessagingAdminException(
          MessagingClientErrorCode.serverUnavailable,
        );

      await expectLater(
        _handle(sender),
        throwsA(
          isA<InvalidArgumentError>().having(
            (e) => e.message,
            'message',
            contains('server-unavailable'),
          ),
        ),
      );
    });

    // These paths only became reachable once `handleSendNotification` started
    // parsing the raw request itself — previously `fromJson` ran inside
    // `firebase_functions`' callable machinery, where a `FormatException`
    // turned into an opaque `internal` error before any test here could see
    // it.
    group('a malformed request', () {
      test('names an unknown event as invalid, not internal', () async {
        final sender = FakeFcmMessageSender();
        final json = <String, dynamic>{
          'token': 'device-token',
          'draft': {'event': 'not-a-real-event', 'title': 'x', 'body': 'y'},
        };

        await expectLater(
          _handle(sender, json: json),
          throwsA(
            isA<InvalidArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Unknown notification event'),
            ),
          ),
        );
      });

      test('a missing token is invalid, not internal', () async {
        final sender = FakeFcmMessageSender();
        final json = <String, dynamic>{'draft': _draft.toJson()};

        await expectLater(
          _handle(sender, json: json),
          throwsA(
            isA<InvalidArgumentError>().having(
              (e) => e.message,
              'message',
              contains('has no token'),
            ),
          ),
        );
      });

      test('a missing draft is invalid, not internal', () async {
        final sender = FakeFcmMessageSender();
        final json = <String, dynamic>{'token': 'device-token'};

        await expectLater(
          _handle(sender, json: json),
          throwsA(
            isA<InvalidArgumentError>().having(
              (e) => e.message,
              'message',
              contains('has no draft'),
            ),
          ),
        );
      });
    });
  });

  group('defaultPayloadId', () {
    test('is prefixed so a sandbox id is recognisable in the inbox', () {
      expect(defaultPayloadId(), startsWith('sandbox-'));
    });

    test('does not repeat within a run', () {
      expect(defaultPayloadId(), isNot(defaultPayloadId()));
    });
  });
}
