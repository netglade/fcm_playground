import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/notification_appearance.dart';
import 'package:fcm_app/domains/notifications/notification_channels.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Where a notification's Android category rides in the payload.
///
/// A property of the *notification*, not the channel — hence read per message
/// rather than kept in the channel table.
const pushCategoryKey = 'category';

/// The notification both isolates draw.
///
/// Top-level, not a method on the presenter: the background isolate needs the
/// same construction, and a second copy would let a notification drawn while the
/// app was dead differ from one drawn on screen.
///
/// [picture] and [largeIcon] are the bytes `loadNotificationImages` fetched, if
/// any. They arrive as arguments rather than being downloaded here so this stays
/// synchronous, and so the suite can pin every style without a network.
NotificationDetails buildNotificationDetails(
  PushMessage message, {
  Uint8List? picture,
  Uint8List? largeIcon,
}) {
  // An unknown id falls back rather than passing through: an unregistered
  // channel draws nothing at all on Android O+, so obeying the payload
  // literally would lose the notification.
  final channel =
      channelById(message.data[pushChannelKey]) ?? defaultNotificationChannel;
  final appearance = appearanceFor(
    message,
    picture: picture,
    largeIcon: largeIcon,
  );

  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      t.channelName(channel.id),
      channelDescription: t.channelDescription(channel.id),
      importance: channel.importance,
      priority: _priorityFor(channel.importance),
      category: _categoryFor(message.data[pushCategoryKey]),
      // The style, the avatar and the progress bar all come from one reading of
      // the payload — see `appearanceFor` for why they are gathered together.
      styleInformation: appearance.style,
      largeIcon: appearance.largeIcon,
      showProgress: appearance.showProgress,
      maxProgress: appearance.maxProgress,
      progress: appearance.progress,
      // Without this a swipe is not reported at all. `main`, because a
      // background dismissal reaches a fresh isolate holding only the message
      // id, and `dismissed` needs the trace id on the stored payload.
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
            // A reply is answered in the shade, so it must NOT show UI —
            // that is what routes the press to the background isolate. Every
            // other action opens the app instead.
            showsUserInterface: !action.takesInput,
            // A plain action's notification is stale once pressed; a
            // reply's is not, and cancelling would delete what the background
            // isolate is updating in place.
            cancelNotification: !action.takesInput,
            inputs: [
              if (action.takesInput)
                AndroidNotificationActionInput(label: action.label),
            ],
          ),
      ],
    ),
    // No actions: iOS takes them from a fixed `UNNotificationCategory`
    // registered at startup, so a per-message list has nowhere to go. See
    // docs/notifications.md.
    iOS: const DarwinNotificationDetails(),
  );
}

/// The pre-Oreo priority matching [importance].
///
/// Ignored from Android O on, where the channel decides — but `minSdk` is below
/// that, and a `Priority.high` on a low-importance channel would disagree on
/// exactly the devices that still read it.
Priority _priorityFor(Importance importance) => switch (importance) {
  Importance.min => Priority.min,
  Importance.low => Priority.low,
  Importance.high || Importance.max => Priority.high,
  _ => Priority.defaultPriority,
};

/// The category [value] names, or null when it names none.
///
/// Null rather than a throw — an unknown category costs a grouping hint, not the
/// notification.
AndroidNotificationCategory? _categoryFor(String? value) => switch (value) {
  'alarm' => AndroidNotificationCategory.alarm,
  'call' => AndroidNotificationCategory.call,
  'message' => AndroidNotificationCategory.message,
  'reminder' => AndroidNotificationCategory.reminder,
  _ => null,
};
