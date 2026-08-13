import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';
import 'send_outcome.dart';

/// Injects the delivery target and a trace id into the message and forwards it
/// to FCM.
///
/// The payload is otherwise the caller's: nothing here invents a notification
/// block or a data key of its own — [request.message] is forwarded untouched
/// apart from the [request.target] injected as the delivery target and the
/// trace id injected into `data`. Takes its clock and its id generator as
/// parameters rather than reading either from the environment, so its tests
/// assert exact values instead of matching patterns — and it depends on no
/// `Request`, no credential and no socket.
Future<SendOutcome> sendMessage(
  SendMessageRequest request, {
  required FcmSender sender,
  required DateTime Function() now,
  required String Function() newTraceId,
}) async {
  if (request.target case AllDevicesTarget()) {
    return _allDevicesUnsupported;
  }

  // Minted once, so the id on the wire and the id returned are the same one.
  final traceId = newTraceId();

  try {
    final messageId = await sender.send(_bodyFor(request, traceId));

    return SendSucceeded(
      SendMessageResponse(
        messageId: messageId,
        sentAt: now(),
        traceId: traceId,
      ),
    );
  } on FcmSendException catch (error) {
    return SendRejected(
      statusCode: _statusFor(error.status),
      error: ApiError(_messageFor(error)),
    );
  }
}

/// Builds FCM's request body, merging [traceId] into the message's `data`.
///
/// The merge builds a **new** map. `FcmMessage.toJson` returns a fresh outer map
/// but passes `data` through by reference, so writing into that map in place
/// would rewrite the caller's own — and for the `const` scenario templates, or
/// the unmodifiable map `FcmMessage.fromJson` produces, it would throw instead.
/// Neither is a way to send a push.
Map<String, Object?> _bodyFor(SendMessageRequest request, String traceId) {
  final message = request.message.toJson();

  return {
    'validate_only': request.validateOnly,
    'message': {
      ...message,
      'data': {
        ...?message['data'] as Map<String, String>?,
        'trace_id': traceId,
      },
      ...request.target.toJson(),
    },
  };
}

/// AllDevices is the one target FCM cannot express: it has no such audience, so
/// honouring it needs a registry of tokens this app does not keep. Refusing with
/// a reason beats sending to one device and calling it a broadcast.
const _allDevicesUnsupported = SendRejected(
  statusCode: 501,
  error: ApiError(
    'sending to all devices needs a token registry, which this API does not '
    'have yet — pick a token, topic or condition',
    field: 'all_devices',
  ),
);

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
