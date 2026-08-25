import 'package:core/core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/notification_content.dart';
import 'notification_details_builder.dart';
import 'notification_group_summary.dart';
import 'notification_reply.dart';

/// Whether the background isolate should draw [message] itself.
///
/// Only when FCM will not. A payload carrying a notification block already has a
/// tray entry — buttonless, because an FCM-drawn notification cannot have
/// actions — and a second one drawn beside it would be two notifications for one
/// push. A payload with both is therefore the old behaviour rather than a
/// duplicate: honest, and the reason the action scenarios go data-only.
bool shouldDrawInBackground(RemoteMessage message) =>
    message.notification == null;

/// Draws [message] from the background isolate.
///
/// Builds its own plugin: this runs in an isolate where `configureDependencies`
/// has not run, so `getIt` would throw and the singletons the UI isolate holds do
/// not exist here.
///
/// The channel is created again rather than assumed. Creating one that exists is
/// a no-op, and the alternative is depending on the UI isolate having run first
/// — which it will have, but only until the day it has not.
Future<void> drawBackgroundNotification(PushMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    // The same callback the main isolate and the response isolate's own
    // `initialize` call (`notification_reply.dart`) both register, so the
    // registration is correct whichever of the three happens to run last. On
    // the pinned `flutter_local_notifications` 22.3.0, the Android side only
    // updates its stored handles when both are supplied together
    // (`FlutterLocalNotificationsPlugin.java:1744-1747`), so a partial
    // initialize does not clear the other's registration on this version —
    // passing it here is defence against a plugin that behaves differently,
    // not a fix for a clobber anyone has observed.
    onDidReceiveBackgroundNotificationResponse: onNotificationReply,
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          notificationChannelId,
          notificationChannelName,
          description: notificationChannelDescription,
          importance: Importance.high,
        ),
      );

  await plugin.show(
    id: notificationIdOf(message),
    title: message.title,
    body: message.body,
    notificationDetails: buildNotificationDetails(message),
    // The same payload the foreground path uses, so a press resolves back to the
    // message through exactly one code path.
    payload: message.id,
  );
  await postGroupSummary(message, plugin: plugin);
}
