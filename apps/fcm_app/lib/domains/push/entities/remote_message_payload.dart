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
/// Two fields come from *outside* `notification.title` and `notification.body`:
/// `tag`, and [pushChannelKey] from `notification.android.channelId` — which is
/// where FCM puts the channel Android itself would draw through, so carrying it
/// is what lets a foreground draw use the same channel as a background one.
///
/// The two differ on absence, deliberately. `tag` is carried even when null,
/// because a null tag is a meaningful answer the parser reads. The channel is
/// omitted entirely, so an empty string cannot be mistaken for a channel
/// actually named ''.
Map<String, Object?> remoteMessageToPayload(RemoteMessage message) => {
  'id': message.messageId ?? '',
  'title': message.notification?.title ?? '',
  'body': message.notification?.body ?? '',
  'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
  'tag': message.notification?.android?.tag,
  if (message.notification?.android?.channelId case final channelId?
      when channelId.isNotEmpty)
    pushChannelKey: channelId,
  ...message.data,
};
