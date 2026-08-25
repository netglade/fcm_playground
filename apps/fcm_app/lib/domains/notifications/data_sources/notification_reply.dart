import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
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

  return PendingReply(id, text, actionId: response.actionId ?? 'reply');
}

/// Redraws the notification to show where the reply has got to.
///
/// Keyed on [messageId] alone, via [notificationIdFor] rather than
/// `notificationIdOf` — this isolate gets only the payload string off the
/// notification response, never the `PushMessage` a tag lives on. For every
/// scenario that uses inline reply the original message carries no tag, so
/// `notificationIdOf` reduces to the same id and this still replaces it as
/// intended.
///
/// Known limitation: the redraw below diverges from the original draw in six
/// ways — five because it builds a fixed `NotificationDetails`, and one because
/// of the id it is keyed on, explained above.
///
/// Four are reachable only by hand. A tagged message's progress notification
/// lands beside the original instead of replacing it. A grouped one leaves its
/// group — it stops counting toward the summary's total even though the store
/// still counts it as a member. An ongoing one becomes dismissable. A
/// full-screen one stops asking to take over the screen, which is the one
/// divergence worth keeping: a "Sending…" redraw seizing the lock screen would
/// be worse than the flag being dropped. Reaching any of the four means
/// hand-composing a Sandbox payload that pairs a reply action with a tag, a
/// group, the ongoing flag or a full-screen request, and no catalogue scenario
/// does: `f2_inline_reply` is the only entry carrying an input action, and its
/// payload carries none of the four.
///
/// The other two are reached by f2 itself, every time. The redraw carries no
/// `actions`, so the Reply button does not come back once the reply is sent.
/// And it carries no `dismissIsolate`, which the plugin documents as null
/// meaning not to report a dismissal at all — so swiping the progress
/// notification away records nothing, and the `dismissed` event
/// `f6_delete_intent` exists to show is off on exactly the notification
/// `f2_inline_reply` produces. Both stay as they are because
/// the alternative is plumbing the original payload into an isolate that
/// receives only a message id.
///
/// The original title is not restored, because this isolate does not have it —
/// finding it would mean reading the payload store's pending queue, which the UI
/// isolate owns and drains. Showing the reply itself is both honest and more
/// useful: it is what the user just typed.
Future<void> showReplyProgress(
  String messageId,
  String text, {
  required bool sent,
}) => _draw(messageId, title: sent ? 'Sent' : 'Sending…', body: text);

/// Redraws the notification to say the reply did not go through.
///
/// Only reached when the reply could not be persisted at all: leaving the
/// notification on "Sending…" at that point would be a permanent lie, since the
/// app will never see a reply that never reached storage. "Not sent" is the
/// honest reading — worse-looking than "Sent", but not false.
Future<void> _showReplyFailed(String messageId, String text) =>
    _draw(messageId, title: 'Not sent', body: text);

/// The plugin call both draw functions share, built fresh each time: this runs
/// in an isolate where `configureDependencies` has not run, so there is no
/// existing plugin instance to reuse.
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
    // The same callback `drawBackgroundNotification` and the main isolate both
    // register — passing it here is defence in case a future plugin version
    // clears handles on a partial initialize, not a fix for an observed one; see
    // `background_notification_draw.dart` for why.
    onDidReceiveBackgroundNotificationResponse: onNotificationReply,
  );

  await plugin.show(
    id: notificationIdFor(messageId),
    title: title,
    body: body,
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

/// Runs [action], logging rather than propagating a failure, and reporting
/// whether it succeeded.
///
/// [onNotificationReply] is a plugin entry point running in a fresh isolate: an
/// exception escaping it has nowhere useful to go, the same reasoning
/// `report_push_event.dart`'s `_swallow` and `main.dart`'s background-draw
/// `debugPrint` already apply to their own calls. [label] names the step that
/// failed, so the log line says which one without the caller having to repeat it.
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
/// Must be top-level and annotated so AOT compilation keeps it reachable: the
/// plugin stores a handle to it natively and calls it in a fresh isolate, where
/// `configureDependencies` has not run and a `getIt` lookup would throw.
///
/// There is no server. The gap between `Sending…` and `Sent` is simulated — the
/// same note the catalogue scenario that exercises this carries — because what
/// this demonstrates is a background isolate updating a notification in place
/// after a press that never opened the app, not a network round trip.
///
/// Every step is guarded with [_attempt] rather than left to throw, because a
/// bare exception here would abandon whichever draw was on screen — most often
/// "Sending…" — forever, with no error, no log and no test to catch it. That is
/// the exact silent-failure shape this isolate exists to close, so it must not
/// reappear inside its own error handling.
@pragma('vm:entry-point')
Future<void> onNotificationReply(NotificationResponse response) async {
  // This isolate has its own memory and its own plugin registry, so both need
  // setting up before shared_preferences can be reached — the same reasoning
  // `main.dart`'s `_onBackgroundMessage` gives for its own call. Without this,
  // `SharedPreferencesReplyStore`'s `SharedPreferencesAsync` throws the moment
  // it is constructed, and every reply is lost with only a `debugPrint` to show
  // for it.
  DartPluginRegistrant.ensureInitialized();

  final reply = replyFrom(response);
  if (reply == null) {
    return;
  }

  await _attempt(
    () => showReplyProgress(reply.messageId, reply.text, sent: false),
    'Could not draw the "Sending…" notification for ${reply.messageId}',
  );

  // Attempted before the second draw, so a reply survives this isolate being
  // killed between the two — the app has it either way.
  final saved = await _attempt(
    () => SharedPreferencesReplyStore().appendPending(reply),
    'Reply to ${reply.messageId} could not be saved',
  );
  if (!saved) {
    // The reply never reached storage, so the app will never merge it — leaving
    // "Sending…" standing would promise a delivery that is not coming. Guarded
    // the same way, so a failure in the recovery draw itself is logged instead
    // of escaping unguarded.
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
    // The reply is safely saved even though this draw failed, so one more
    // attempt is worth making rather than leaving "Sending…" as the last word
    // for a reply that in fact went through.
    await _attempt(
      () => showReplyProgress(reply.messageId, reply.text, sent: true),
      'Retry of the "Sent" notification for ${reply.messageId} also failed',
    );
  }
}
