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
    actions: [
      for (final action in parseNotificationActions(
        message.data[notificationActionsKey],
      ))
        AndroidNotificationAction(
          action.id,
          action.label,
          // Every action in this cycle opens the app. That is what keeps
          // `onDidReceiveBackgroundNotificationResponse` out of the design:
          // it exists for actions that do not show UI.
          showsUserInterface: true,
          cancelNotification: true,
        ),
    ],
  ),
  // No actions: iOS takes them from a `UNNotificationCategory` registered at
  // startup with a fixed set, so an arbitrary per-message list has nowhere
  // to go. Documented in the README beside the same limitation on
  // `dismissed`.
  iOS: const DarwinNotificationDetails(),
);
