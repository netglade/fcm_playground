import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:firebase_functions/firebase_functions.dart';

import 'fcm_message_sender.dart';
import 'notification_message_builder.dart';

/// The `id` a payload gets when the caller does not supply one.
///
/// Prefixed so a message sent from the sandbox is recognisable in the inbox at
/// a glance, and microsecond-stamped so two sends in the same second differ.
String defaultPayloadId() => 'sandbox-${DateTime.now().microsecondsSinceEpoch}';

/// Parses [json], validates it, sends it, and reports what was sent.
///
/// Takes its collaborators as parameters — the sender, the id generator and the
/// clock — so the whole thing is testable without a Firebase runtime. The
/// registration in `register_functions.dart` supplies only the sender and lets
/// the other two default.
///
/// Takes the raw request body rather than an already-parsed
/// [SendNotificationRequest] so that `SendNotificationRequest.fromJson`'s
/// [FormatException]s — an unknown event, a missing token, a missing draft —
/// are caught here and turned into [InvalidArgumentError]. Parsing it one
/// frame up, inside `firebase_functions`' callable machinery, would let those
/// exceptions fall through the framework's generic catch-all and reach the
/// client as an opaque `internal` error with no detail.
///
/// Throws [InvalidArgumentError] for anything the caller can fix: a malformed
/// request, an invalid draft, a blank token, or an FCM rejection of the token
/// itself. That is a native callable error, so the app receives it as
/// `FirebaseFunctionsException(code: 'invalid-argument')` rather than an opaque
/// HTTP failure.
Future<SendNotificationResponse> handleSendNotification(
  Map<String, dynamic> json, {
  required FcmMessageSender sender,
  String Function() newPayloadId = defaultPayloadId,
  DateTime Function() now = DateTime.now,
}) async {
  final SendNotificationRequest request;
  try {
    request = SendNotificationRequest.fromJson(json);
  } on FormatException catch (error) {
    throw InvalidArgumentError(error.message);
  }

  final problems = const NotificationDraftValidator().validate(request.draft);
  if (problems.isNotEmpty) {
    throw InvalidArgumentError(problems.join('; '));
  }
  if (request.token.trim().isEmpty) {
    throw InvalidArgumentError('token must not be blank');
  }

  final payloadId = newPayloadId();
  final sentAt = now().toUtc();
  final message = const NotificationMessageBuilder().build(
    draft: request.draft,
    token: request.token,
    payloadId: payloadId,
    sentAt: sentAt,
  );

  try {
    final messageId = await sender.send(message);

    return SendNotificationResponse(
      messageId: messageId,
      payloadId: payloadId,
      sentAt: sentAt,
    );
  } on FirebaseMessagingAdminException catch (error) {
    throw InvalidArgumentError(_explain(error));
  }
}

/// Turns an Admin SDK error into something a person can act on.
///
/// An unregistered token is by far the most common failure in a sandbox — the
/// app was reinstalled, or the token rotated — and deserves better than the raw
/// `registration-token-not-registered`.
String _explain(FirebaseMessagingAdminException error) =>
    switch (error.errorCode) {
      MessagingClientErrorCode.registrationTokenNotRegistered =>
        'This device is no longer registered with FCM. Restart the app to pick '
            'up a fresh token, then send again.',
      MessagingClientErrorCode.invalidRegistrationToken =>
        'The registration token is malformed.',
      _ => 'FCM rejected the message: ${error.code}',
    };
