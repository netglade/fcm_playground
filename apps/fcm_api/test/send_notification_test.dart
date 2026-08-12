import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Future<SendOutcome> run(
    SendNotificationRequest request, {
    FakeFcmSender? sender,
  }) => sendNotification(
    request,
    sender: sender ?? FakeFcmSender(),
    newPayloadId: () => 'api-1754812345678901',
    now: () => sentAt,
  );

  SendNotificationRequest request({
    String token = 'device-token',
    String title = 'Build finished',
    String body = 'main #128 passed',
    Map<String, String> data = const {},
  }) => SendNotificationRequest(
    token: token,
    draft: NotificationDraft(title: title, body: body, data: data),
  );

  group('sendNotification', () {
    test(
      'reports the id and timestamp it stamped, not the caller\'s',
      () async {
        final outcome = await run(request());

        expect(outcome, isA<SendSucceeded>());
        final response = (outcome as SendSucceeded).response;
        expect(response.payloadId, 'api-1754812345678901');
        expect(response.sentAt, sentAt);
        expect(response.messageId, 'projects/p/messages/0:17');
      },
    );

    test('hands FCM the message built from the draft', () async {
      final sender = FakeFcmSender();

      await run(request(data: {'event': 'build_finished'}), sender: sender);

      expect(sender.sent, hasLength(1));
      final message = sender.sent.single['message']! as Map<String, Object?>;
      final data = message['data']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
      expect(data['id'], 'api-1754812345678901');
      expect(data['event'], 'build_finished');
    });

    test('rejects a blank token with 400, naming the field', () async {
      final outcome = await run(request(token: '  '));

      expect(outcome, isA<SendRejected>());
      final rejected = outcome as SendRejected;
      expect(rejected.statusCode, 400);
      expect(rejected.error.field, 'token');
    });

    test('rejects an invalid draft with 400 and does not call FCM', () async {
      final sender = FakeFcmSender();

      final outcome = await run(request(title: ''), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.field, 'title');
      expect(outcome.error.message, contains('must not be blank'));
      expect(sender.sent, isEmpty);
    });

    test('rejects a draft whose data collides with a reserved key', () async {
      final outcome = await run(request(data: {'sentAt': 'now'}));

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.field, 'data.sentAt');
    });

    test('maps an unregistered token to 404 with wording of its own', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'UNREGISTERED',
          message: 'Requested entity was not found.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 404);
      expect(outcome.error.message, contains('no longer valid'));
      expect(outcome.error.message, isNot(contains('UNREGISTERED')));
    });

    test('maps a rejected argument to 400', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'INVALID_ARGUMENT',
          message: 'The registration token is not a valid FCM token.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.message, contains('not a valid FCM token'));
    });

    test('maps anything else to 502, carrying FCM\'s status', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'QUOTA_EXCEEDED',
          message: 'Too many requests.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 502);
      expect(outcome.error.message, contains('QUOTA_EXCEEDED'));
      expect(outcome.error.field, isNull);
    });
  });
}
