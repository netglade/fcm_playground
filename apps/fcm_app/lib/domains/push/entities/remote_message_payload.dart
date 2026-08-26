import 'package:firebase_messaging/firebase_messaging.dart';

/// Where the drawn notification's channel id rides in the flattened payload.
///
/// Read by `buildNotificationDetails`, and passed straight through by
/// `PushMessageParser` — it is not a reserved key, so it also shows on the message
/// detail page as a data row, which is honest: it is something the sender chose.
const pushChannelKey = 'channel';

/// Flattens a [RemoteMessage] into the flat map `PushMessageParser` expects.
///
/// Top-level rather than a method on the source, because the background isolate
/// needs the same mapping and a second copy would let the two paths drift.
///
/// The notification block supplies defaults; anything in `data` wins. Missing
/// fields become blanks rather than nulls, so the parser rejects them by name
/// instead of throwing on a null.
///
/// [pushChannelKey] is the one field taken from *outside* `notification.title`
/// and `notification.body` — it comes from `notification.android.channelId`,
/// which is where FCM puts the channel Android itself would draw through. Carrying
/// it is what lets a foreground draw use the same channel as a background one.
/// It is omitted rather than blanked when absent, so an empty string cannot be
/// mistaken for a channel actually named ''.
Map<String, Object?> remoteMessageToPayload(RemoteMessage message) => {
  'id': message.messageId ?? '',
  'title': message.notification?.title ?? '',
  'body': message.notification?.body ?? '',
  'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
  if (message.notification?.android?.channelId case final channelId?
      when channelId.isNotEmpty)
    pushChannelKey: channelId,
  ...message.data,
};
