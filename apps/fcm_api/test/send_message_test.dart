import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Future<SendOutcome> run(
    SendMessageRequest request, {
    FakeFcmSender? sender,
  }) => sendMessage(
    request,
    sender: sender ?? FakeFcmSender(),
    now: () => sentAt,
  );

  SendMessageRequest request({
    SendTarget target = const TokenTarget('device-token'),
    bool validateOnly = false,
    FcmMessage message = const FcmMessage(
      notification: FcmNotification(title: 'Build finished'),
    ),
  }) => SendMessageRequest(
    target: target,
    message: message,
    validateOnly: validateOnly,
  );

  group('sendMessage', () {
    test(
      'reports the message name FCM assigned and its own send time',
      () async {
        final outcome = await run(request());

        final response = (outcome as SendSucceeded).response;
        expect(response.messageId, 'projects/p/messages/0:17');
        expect(response.sentAt, sentAt);
      },
    );

    test('injects the token into the message, which is the target', () async {
      final sender = FakeFcmSender();

      await run(request(), sender: sender);

      final message = sender.sent.single['message']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
    });

    test(
      'forwards the payload as written, adding nothing of its own',
      () async {
        final sender = FakeFcmSender();

        await run(
          request(
            message: FcmMessage.fromJson({
              'data': {'event': 'sync'},
              'android': {'priority': 'HIGH'},
            }),
          ),
          sender: sender,
        );

        final message = sender.sent.single['message']! as Map<String, Object?>;
        expect(message['data'], {'event': 'sync'});
        expect(message['android'], {'priority': 'HIGH'});
        // The server used to invent these. It must not any more.
        expect(message.keys, isNot(contains('notification')));
        expect(
          (message['data']! as Map<String, Object?>).keys,
          isNot(contains('id')),
        );
      },
    );

    test('forwards validate_only so FCM checks without delivering', () async {
      final sender = FakeFcmSender();

      await run(request(validateOnly: true), sender: sender);

      expect(sender.sent.single['validate_only'], isTrue);
    });

    test('sends validate_only as false by default', () async {
      final sender = FakeFcmSender();

      await run(request(), sender: sender);

      expect(sender.sent.single['validate_only'], isFalse);
    });

    test('forwards a topic as the delivery target', () async {
      final sender = FakeFcmSender();

      final outcome = await run(
        request(target: const TopicTarget('news'), message: const FcmMessage()),
        sender: sender,
      );

      expect(outcome, isA<SendSucceeded>());
      expect(sender.sent.single['message'], containsPair('topic', 'news'));
    });

    test('refuses all-devices with 501 rather than sending to one', () async {
      final sender = FakeFcmSender();

      final outcome = await run(
        request(target: const AllDevicesTarget()),
        sender: sender,
      );

      expect(outcome, isA<SendRejected>());
      expect((outcome as SendRejected).statusCode, 501);
      expect(outcome.error.field, 'all_devices');
      expect(sender.sent, isEmpty, reason: 'nothing may be sent');
    });

    test('a blank token is still a 400, now via the target reader', () {
      // The guard moved into SendTarget.readFrom; the guarantee did not move.
      expect(
        () => SendMessageRequest.fromJson({
          'token': '  ',
          'message': <String, Object?>{},
        }),
        throwsA(isA<FormatException>()),
      );
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
    });

    test('maps a rejected argument to 400', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'INVALID_ARGUMENT',
          message: 'Invalid value at message.android.ttl.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.message, contains('message.android.ttl'));
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
    });
  });
}
