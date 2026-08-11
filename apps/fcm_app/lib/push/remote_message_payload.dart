import 'package:firebase_messaging/firebase_messaging.dart';

/// Flattens a [RemoteMessage] into the flat map `PushMessageParser` expects.
///
/// A top-level function rather than a method on the source, because the
/// background isolate needs exactly this mapping too — and a second copy of it
/// would let the foreground and background paths drift apart.
///
/// The notification block supplies defaults; anything in `data` wins, since a
/// data-only push is the case worth supporting well. Missing fields become
/// blanks rather than nulls, so the parser rejects them by name instead of
/// throwing on a null.
Map<String, Object?> remoteMessageToPayload(RemoteMessage message) => {
  'id': message.messageId ?? '',
  'title': message.notification?.title ?? '',
  'body': message.notification?.body ?? '',
  'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
  ...message.data,
};
