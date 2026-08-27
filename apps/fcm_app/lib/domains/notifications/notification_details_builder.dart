import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../i18n/channel_text.dart';
import '../../../i18n/translations.g.dart';
import '../push/notification_action.dart';
import '../push/push_message.dart';
import '../push/remote_message_payload.dart';
import 'notification_channels.dart';
import 'notification_content.dart';

/// Where a notification's Android category rides in the payload.
///
/// A category is a property of the *notification*, not of the channel, which is
/// why it is read per message here instead of sitting in the channel table.
const pushCategoryKey = 'category';

/// The notification both isolates draw.
///
/// Top-level rather than a method on the presenter, for the reason
/// `remoteMessageToPayload` is top-level: the background isolate needs the same
/// construction, and a second copy would let a notification drawn while the app
/// was dead differ from one drawn while it was on screen.
NotificationDetails buildNotificationDetails(PushMessage message) {
  // An unknown id falls back rather than being passed through: a channel the app
  // never registered draws nothing at all on Android O+, so honouring the
  // payload literally would lose the notification.
  final channel =
      channelById(message.data[pushChannelKey]) ?? defaultNotificationChannel;

  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      t.channelName(channel.id),
      channelDescription: t.channelDescription(channel.id),
      importance: channel.importance,
      priority: _priorityFor(channel.importance),
      category: _categoryFor(message.data[pushCategoryKey]),
      // Without this, a swipe is not reported at all. `main` rather than
      // `background`: a background dismissal reaches a fresh isolate carrying
      // only the message id, and `dismissed` has to be recorded against the
      // trace id on the stored payload.
      dismissIsolate: NotificationDismissedIsolate.main,
      // Only the documented value. See `notificationOngoingKey`.
      ongoing: message.data[notificationOngoingKey] == 'true',
      // An ongoing notification a tap removes is not ongoing.
      autoCancel: message.data[notificationOngoingKey] != 'true',
      groupKey: message.data[notificationGroupKey],
      // Only the documented value. See `notificationFullScreenKey`.
      fullScreenIntent: message.data[notificationFullScreenKey] == 'true',
      actions: [
        for (final action in parseNotificationActions(
          message.data[notificationActionsKey],
        ))
          AndroidNotificationAction(
            action.id,
            action.label,
            // A reply is answered in the shade, so it must NOT show UI: that
            // is what routes the press to the background isolate instead of
            // the main one. Every other action opens the app, which is what
            // lets `LocalNotificationPresenter` answer for it.
            showsUserInterface: !action.takesInput,
            // A plain action's notification is stale the moment it is
            // pressed. A reply's is not — the background isolate updates it
            // in place, and cancelling would delete the thing being updated.
            cancelNotification: !action.takesInput,
            inputs: [
              if (action.takesInput)
                AndroidNotificationActionInput(label: action.label),
            ],
          ),
      ],
    ),
    // No actions: iOS takes them from a `UNNotificationCategory` registered at
    // startup with a fixed set, so an arbitrary per-message list has nowhere
    // to go. Documented in docs/notifications.md beside the same limitation on
    // `dismissed`.
    iOS: const DarwinNotificationDetails(),
  );
}

/// The pre-Oreo priority matching [importance].
///
/// Ignored from Android O onwards, where the channel decides — but the app's
/// `minSdk` is below that, and a `Priority.high` on a low-importance channel
/// would make the two disagree on exactly the devices that read it.
Priority _priorityFor(Importance importance) => switch (importance) {
  Importance.min => Priority.min,
  Importance.low => Priority.low,
  Importance.high || Importance.max => Priority.high,
  _ => Priority.defaultPriority,
};

/// The category [value] names, or null when it names none.
///
/// Null rather than a throw: a category the plugin does not know costs a
/// grouping hint, not the notification.
AndroidNotificationCategory? _categoryFor(String? value) => switch (value) {
  'alarm' => AndroidNotificationCategory.alarm,
  'call' => AndroidNotificationCategory.call,
  'message' => AndroidNotificationCategory.message,
  'reminder' => AndroidNotificationCategory.reminder,
  _ => null,
};
