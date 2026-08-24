import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../push/data_sources/shared_preferences_reply_store.dart';
import '../../push/entities/pending_reply.dart';
import '../entities/notification_content.dart';

/// The reply [response] carries, or null when it carries none.
///
/// Null covers a plain action press as well as a malformed response: a plain
/// action opens the app and is answered in the main isolate, so this isolate has
/// nothing to do with it.
PendingReply? replyFrom(NotificationResponse response) {
  final id = response.payload;
  final text = response.input;
  if (id == null || id.isEmpty || text == null) {
    return null;
  }

  return PendingReply(id, text);
}

/// Redraws the notification to show where the reply has got to.
///
/// The same [notificationIdFor] the original used, so this replaces rather than
/// stacks.
///
/// The original title is not restored, because this isolate does not have it —
/// finding it would mean reading the payload store's pending queue, which the UI
/// isolate owns and drains. Showing the reply itself is both honest and more
/// useful: it is what the user just typed.
Future<void> showReplyProgress(
  String messageId,
  String text, {
  required bool sent,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: onNotificationReply,
  );

  await plugin.show(
    id: notificationIdFor(messageId),
    title: sent ? 'Sent' : 'Sending…',
    body: text,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: messageId,
  );
}

/// Handles a press on an action that does not open the app.
///
/// Must be top-level and annotated so AOT compilation keeps it reachable: the
/// plugin stores a handle to it natively and calls it in a fresh isolate, where
/// `configureDependencies` has not run and a `getIt` lookup would throw.
///
/// There is no server. The gap between `Sending…` and `Sent` is simulated, and
/// f2's `expectation` says so — what this demonstrates is a background isolate
/// updating a notification in place after a press that never opened the app, not
/// a network round trip.
@pragma('vm:entry-point')
Future<void> onNotificationReply(NotificationResponse response) async {
  final reply = replyFrom(response);
  if (reply == null) {
    return;
  }

  await showReplyProgress(reply.messageId, reply.text, sent: false);
  // Appended before the second draw, so a reply survives this isolate being
  // killed between the two — the app has it either way.
  await SharedPreferencesReplyStore().appendPending(reply);
  await Future<void>.delayed(const Duration(seconds: 1));
  await showReplyProgress(reply.messageId, reply.text, sent: true);
}
