import 'dart:typed_data';

import 'package:fcm_app/domains/push/push_message.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Where a payload names the style it wants drawn.
///
/// This project's convention, not an FCM field — FCM has no way to ask for an
/// inbox or a messaging notification, so the name rides in `data` and the client
/// builds it.
const pushStyleKey = 'style';

/// The picture `big_picture` downloads, and the avatar `large_icon` downloads.
const pushImageUrlKey = 'image_url';
const pushLargeIconUrlKey = 'large_icon_url';

/// `inbox`: one row per entry, `|`-separated.
const pushLinesKey = 'lines';

/// `messaging`: `Sender:text` entries, `|`-separated, and the thread's title.
const pushMessagesKey = 'messages';
const pushConversationKey = 'conversation';

/// `progress`: how far along, out of how many.
const pushProgressKey = 'progress';
const pushMaxProgressKey = 'max';

/// Everything a payload's [pushStyleKey] decides about how a notification looks.
///
/// Gathered into one object because the six styles do not all live in the same
/// place on `AndroidNotificationDetails`: three are a `StyleInformation`, one is
/// the `largeIcon` field and one is the three progress fields. A caller that
/// switched on the style name itself would have to know which is which.
class NotificationAppearance {
  const NotificationAppearance({
    required this.style,
    this.largeIcon,
    this.showProgress = false,
    this.maxProgress = 0,
    this.progress = 0,
  });

  final StyleInformation style;
  final AndroidBitmap<Object>? largeIcon;
  final bool showProgress;
  final int maxProgress;
  final int progress;
}

/// How [message] should look, given whatever bytes were downloaded for it.
///
/// [picture] and [largeIcon] are passed in rather than fetched here, so this
/// stays synchronous and testable without a network — see
/// `notification_images.dart` for the half that does the downloading.
///
/// Never throws, and never returns nothing: an unknown style name, an image
/// that failed to download, an inbox with no usable rows all fall back to big
/// text. Losing the styling is the cost; losing the notification would not be.
NotificationAppearance appearanceFor(
  PushMessage message, {
  Uint8List? picture,
  Uint8List? largeIcon,
}) {
  final named = message.data[pushStyleKey];
  final progress = named == 'progress' ? _progressOf(message) : null;

  return NotificationAppearance(
    style: _styleFor(named, message, picture) ?? _bigTextFor(message),
    largeIcon: named == 'large_icon' && largeIcon != null
        ? ByteArrayAndroidBitmap(largeIcon)
        : null,
    showProgress: progress != null,
    progress: progress?.value ?? 0,
    maxProgress: progress?.max ?? 0,
  );
}

/// Every app-drawn notification expands, which is what makes a long body
/// readable at all — see `e1_long_text`. It is also the fallback the styles
/// below degrade to.
BigTextStyleInformation _bigTextFor(PushMessage message) =>
    BigTextStyleInformation(message.body, contentTitle: message.title);

/// The style [named] asks for, or null when it cannot be built.
///
/// `large_icon` and `progress` are absent on purpose: neither is a
/// `StyleInformation`, so both are handled by [appearanceFor] directly.
StyleInformation? _styleFor(
  String? named,
  PushMessage message,
  Uint8List? picture,
) => switch (named) {
  'big_picture' when picture != null => BigPictureStyleInformation(
    ByteArrayAndroidBitmap(picture),
    contentTitle: message.title,
    summaryText: message.body,
  ),
  'inbox' => _inboxFor(message),
  'messaging' => _messagingFor(message),
  _ => null,
};

/// The inbox rows [message] carries, or null when it carries none worth drawing.
InboxStyleInformation? _inboxFor(PushMessage message) {
  final lines = _entriesIn(message.data[pushLinesKey]);
  if (lines.isEmpty) {
    return null;
  }

  return InboxStyleInformation(
    lines,
    contentTitle: message.title,
    summaryText: message.body,
  );
}

/// The conversation [message] carries, or null when no entry parses.
MessagingStyleInformation? _messagingFor(PushMessage message) {
  final messages = <Message>[];
  for (final entry in _entriesIn(message.data[pushMessagesKey])) {
    final separator = entry.indexOf(':');
    if (separator < 0) {
      continue;
    }

    final sender = entry.substring(0, separator).trim();
    // Only the first colon separates the sender, the same rule
    // `parseNotificationActions` follows, so a message may contain one.
    final text = entry.substring(separator + 1).trim();
    if (sender.isEmpty || text.isEmpty) {
      continue;
    }

    // Every message is stamped with the push's own time: nothing in the payload
    // says when each was sent, and inventing per-message times would put a
    // false ordering on screen.
    messages.add(Message(text, message.sentAt, Person(name: sender)));
  }

  if (messages.isEmpty) {
    return null;
  }

  return MessagingStyleInformation(
    // Deliberately nameless. This is who *you* are in the thread, for messages
    // attributed to the user — and no entry ever is, so a name here would be
    // invented copy that never appears.
    const Person(),
    conversationTitle: message.data[pushConversationKey],
    messages: messages,
  );
}

/// The two numbers a progress bar needs, or null when either is unreadable.
///
/// Null rather than a default: a bar drawn from a number nobody sent is a
/// made-up figure, and this app exists to show what the payload really did.
({int value, int max})? _progressOf(PushMessage message) {
  final value = int.tryParse(message.data[pushProgressKey] ?? '');
  final max = int.tryParse(message.data[pushMaxProgressKey] ?? '');
  if (value == null || max == null) {
    return null;
  }

  return (value: value, max: max);
}

/// The non-blank `|`-separated entries in [raw].
List<String> _entriesIn(String? raw) => (raw ?? '')
    .split('|')
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList();
