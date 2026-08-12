import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';
import 'send_outcome.dart';

/// Validates the token, injects it into the message and forwards it to FCM.
///
/// The payload is the caller's: nothing here invents a data key or a
/// notification block — [request.message] is forwarded untouched apart from
/// the [request.token] injected as the delivery target. Takes its clock as a
/// parameter rather than reading it from the environment, so its tests assert
/// exact values instead of matching patterns — and it depends on no `Request`,
/// no credential and no socket.
Future<SendOutcome> sendMessage(
  SendMessageRequest request, {
  required FcmSender sender,
  required DateTime Function() now,
}) async {
  if (request.token.trim().isEmpty) {
    return const SendRejected(
      statusCode: 400,
      error: ApiError('token must not be blank', field: 'token'),
    );
  }

  final body = {
    'validate_only': request.validateOnly,
    'message': {...request.message.toJson(), 'token': request.token},
  };

  try {
    final messageId = await sender.send(body);

    return SendSucceeded(
      SendMessageResponse(messageId: messageId, sentAt: now()),
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
