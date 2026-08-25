import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/notification_content.dart';

/// The notification both isolates draw.
///
/// Top-level rather than a method on the presenter, for the reason
/// `remoteMessageToPayload` is top-level: the background isolate needs the same
/// construction, and a second copy would let a notification drawn while the app
/// was dead differ from one drawn while it was on screen.
NotificationDetails buildNotificationDetails(
  PushMessage message,
) => NotificationDetails(
  android: AndroidNotificationDetails(
    notificationChannelId,
    notificationChannelName,
    channelDescription: notificationChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
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
  // to go. Documented in the README beside the same limitation on
  // `dismissed`.
  iOS: const DarwinNotificationDetails(),
);
