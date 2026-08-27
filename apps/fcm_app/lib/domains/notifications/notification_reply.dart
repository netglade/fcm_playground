import 'dart:ui' show DartPluginRegistrant;

import 'package:fcm_app/domains/notifications/notification_channels.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The reply [response] carries, or null when it carries none.
///
/// Null also covers a plain action press, which opens the app and is answered
/// in the main isolate instead.
PendingReply? replyFrom(NotificationResponse response) {
  final id = response.payload;
  final text = response.input;
  if (id == null || id.isEmpty || text == null) {
    return null;
  }

  return PendingReply(id, text, actionId: response.actionId ?? 'reply');
}

/// Redraws the notification to show where the reply has got to.
///
/// Keyed on [messageId] via [notificationIdFor], not `notificationIdOf`: this
/// isolate gets only the payload string, never the `PushMessage` a tag lives
/// on.
///
/// The redraw builds a fixed `NotificationDetails`, so it diverges from the
/// original draw. Two divergences hit `f2_inline_reply` every time: no
/// `actions`, so the Reply button does not come back; and no `dismissIsolate`,
/// which the plugin treats as "do not report dismissals" — so swiping the
/// progress notification records nothing. Four more (tag, group, ongoing,
/// full-screen all dropped) need a hand-composed Sandbox payload, since no
/// catalogue scenario pairs a reply action with them.
///
/// All of it stays as-is: the alternative is plumbing the original payload into
/// an isolate that receives only a message id. The original title is not
/// restored for the same reason — and showing the typed reply is more useful.
Future<void> showReplyProgress(
  String messageId,
  String text, {
  required bool sent,
}) =>
    _draw(messageId, title: sent ? t.reply.sent : t.reply.sending, body: text);

/// Redraws the notification to say the reply did not go through.
///
/// Only when the reply could not be persisted at all. Leaving "Sending…" would
/// be a permanent lie: the app will never see a reply that never reached
/// storage.
Future<void> _showReplyFailed(String messageId, String text) =>
    _draw(messageId, title: t.reply.not_sent, body: text);

/// The plugin call both draws share, built fresh each time — this isolate never
/// ran `configureDependencies`, so there is no instance to reuse.
Future<void> _draw(
  String messageId, {
  required String title,
  required String body,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    // Defence in case a future plugin version clears handles on a partial
    // initialize, not a fix for an observed bug — see
    // `background_notification_draw.dart`.
    onDidReceiveBackgroundNotificationResponse: onNotificationReply,
  );
  await registerNotificationChannels(plugin);

  await plugin.show(
    id: notificationIdFor(messageId),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        t.channelName(notificationChannelId),
        channelDescription: t.channelDescription(notificationChannelId),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: messageId,
  );
}

/// Runs [action], logging rather than propagating a failure, and reporting
/// whether it succeeded.
///
/// An exception escaping a plugin entry point in a fresh isolate has nowhere to
/// go. [label] names the step, so the log line says which one failed.
Future<bool> _attempt(Future<void> Function() action, String label) async {
  try {
    await action();

    return true;
  } on Object catch (error) {
    debugPrint('$label: $error');

    return false;
  }
}

/// Handles a press on an action that does not open the app.
///
/// Must be top-level and annotated so AOT keeps it reachable: the plugin stores
/// a native handle and calls it in a fresh isolate, where `getIt` would throw.
///
/// There is no server — the gap between "Sending…" and "Sent" is simulated.
/// What this demonstrates is a background isolate updating a notification in
/// place after a press that never opened the app.
///
/// Every step is guarded with [_attempt]: a bare exception would abandon
/// whichever draw is on screen — usually "Sending…" — forever, with no error
/// and no log. That is the silent failure this isolate exists to close, so it
/// must not reappear in its own error handling.
@pragma('vm:entry-point')
Future<void> onNotificationReply(NotificationResponse response) async {
  // Own memory, own plugin registry, so both need setting up before
  // shared_preferences is reachable. Without this,
  // `SharedPreferencesReplyStore` throws on construction and every reply is
  // lost with only a `debugPrint`.
  DartPluginRegistrant.ensureInitialized();

  await restoreStoredLocale();

  final reply = replyFrom(response);
  if (reply == null) {
    return;
  }

  await _attempt(
    () => showReplyProgress(reply.messageId, reply.text, sent: false),
    'Could not draw the "Sending…" notification for ${reply.messageId}',
  );

  // Before the second draw, so a reply survives this isolate being killed
  // between the two.
  final saved = await _attempt(
    () => SharedPreferencesReplyStore().appendPending(reply),
    'Reply to ${reply.messageId} could not be saved',
  );
  if (!saved) {
    // Never reached storage, so the app will never merge it — leaving
    // "Sending…" would promise a delivery that is not coming.
    await _attempt(
      () => _showReplyFailed(reply.messageId, reply.text),
      'Could not draw the failure notification for ${reply.messageId}',
    );

    return;
  }

  await Future<void>.delayed(const Duration(seconds: 1));

  final drawnSent = await _attempt(
    () => showReplyProgress(reply.messageId, reply.text, sent: true),
    'Could not draw the "Sent" notification for ${reply.messageId}',
  );
  if (!drawnSent) {
    // The reply is saved, so one retry beats leaving "Sending…" as the last
    // word for a reply that went through.
    await _attempt(
      () => showReplyProgress(reply.messageId, reply.text, sent: true),
      'Retry of the "Sent" notification for ${reply.messageId} also failed',
    );
  }
}
