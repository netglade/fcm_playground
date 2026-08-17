import 'package:firebase_messaging/firebase_messaging.dart';

/// Flattens a [RemoteMessage] into the flat map `PushMessageParser` expects.
///
/// Top-level rather than a method on the source, because the background isolate
/// needs the same mapping and a second copy would let the two paths drift.
///
/// The notification block supplies defaults; anything in `data` wins. Missing
/// fields become blanks rather than nulls, so the parser rejects them by name
/// instead of throwing on a null.
Map<String, Object?> remoteMessageToPayload(RemoteMessage message) => {
  'id': message.messageId ?? '',
  'title': message.notification?.title ?? '',
  'body': message.notification?.body ?? '',
  'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
  ...message.data,
};
