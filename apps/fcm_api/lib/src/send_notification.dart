import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';
import 'notification_message.dart';
import 'send_outcome.dart';

/// Validates, stamps and sends one notification.
///
/// Takes its clock and its id generator as parameters rather than reading them
/// from the environment, so its tests assert exact values instead of matching
/// patterns — and it depends on no `Request`, no credential and no socket.
Future<SendOutcome> sendNotification(
  SendNotificationRequest request, {
  required FcmSender sender,
  required String Function() newPayloadId,
  required DateTime Function() now,
}) async {
  if (request.token.trim().isEmpty) {
    return const SendRejected(
      statusCode: 400,
      error: ApiError('token must not be blank', field: 'token'),
    );
  }

  final problems = const NotificationDraftValidator().validate(request.draft);
  if (problems.isNotEmpty) {
    final problem = problems.first;

    return SendRejected(
      statusCode: 400,
      error: ApiError('$problem', field: problem.field),
    );
  }

  final message = NotificationMessage(
    token: request.token,
    draft: request.draft,
    payloadId: newPayloadId(),
    sentAt: now(),
  );

  try {
    final messageId = await sender.send(message.toJson());

    return SendSucceeded(
      SendNotificationResponse(
        messageId: messageId,
        payloadId: message.payloadId,
        sentAt: message.sentAt,
      ),
    );
  } on FcmSendException catch (error) {
    return SendRejected(
      statusCode: _statusFor(error.status),
      error: ApiError(_messageFor(error)),
    );
  }
}

/// FCM's error codes, mapped onto the status the caller should see.
int _statusFor(String fcmStatus) => switch (fcmStatus) {
  'UNREGISTERED' => 404,
  'INVALID_ARGUMENT' => 400,
  _ => 502,
};

/// A stale token is the common failure and gets wording of its own, because
/// `UNREGISTERED` tells the person holding the phone nothing.
String _messageFor(FcmSendException error) => switch (error.status) {
  'UNREGISTERED' =>
    'The registration token is no longer valid — the app was reinstalled or '
        'the token rotated. Restart the app to get a fresh one.',
  'INVALID_ARGUMENT' => 'FCM rejected the message: ${error.message}',
  _ => 'FCM failed (${error.status}): ${error.message}',
};
