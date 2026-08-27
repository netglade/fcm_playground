import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/notifications/notification_group_store.dart';
import 'package:fcm_app/domains/notifications/shared_preferences_notification_group_store.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// [groups] with [messageId] recorded in [group], unchanged if already there.
///
/// Pure, so the membership rule is testable without a plugin — the posting
/// around it is not.
Map<String, List<String>> withMemberAdded(
  Map<String, List<String>> groups,
  String group,
  String messageId,
) {
  final members = groups[group] ?? const <String>[];
  if (members.contains(messageId)) {
    return groups;
  }

  return {
    ...groups,
    group: [...members, messageId],
  };
}

/// What the summary row says.
///
/// The group name is used as the sender gave it — the app cannot know its
/// singular, and guessing would be wrong more often than not.
String groupSummaryText(int count, String group) => '$count $group';

/// Records [message] in its group and redraws that group's summary.
///
/// Called by both drawing paths right after the notification itself, so a
/// summary never appears in one app state and not the other. [plugin] and
/// [store] are injectable so each caller can pass the instance its own isolate
/// already has; the background isolate has none and defaults, which is safe
/// because both write the same key. The posting itself has no test seam.
///
/// Every fallible step is caught and logged rather than thrown: the callers
/// read any exception as "nothing was drawn" and skip the `displayed` event, so
/// a failure escaping here would be blamed on a notification that did appear.
///
/// Does nothing for a message naming no group.
Future<void> postGroupSummary(
  PushMessage message, {
  NotificationGroupStore? store,
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final group = message.data[notificationGroupKey];
  if (group == null || group.isEmpty) {
    return;
  }

  final groupStore = store ?? SharedPreferencesNotificationGroupStore();

  var loaded = const <String, List<String>>{};
  final didLoad = await _attempt(
    () async => loaded = await groupStore.load(),
    'Could not load notification groups while posting the summary for "$group"',
  );
  if (!didLoad) {
    // No group to join and no count to show — nothing safe left to do.
    return;
  }

  final updated = withMemberAdded(loaded, group, message.id);

  await _attempt(
    () => groupStore.save(updated),
    'Could not save notification groups while posting the summary for "$group"',
  );

  await _attempt(
    // If the save above failed, saved and drawn counts disagree. Drawing from
    // [updated] anyway is the best answer available; the next member resaves.
    () => (plugin ?? FlutterLocalNotificationsPlugin()).show(
      // Keyed on the group, so the summary updates in place instead of
      // stacking a row per notification.
      id: notificationIdFor(group),
      title: group,
      body: groupSummaryText(updated[group]!.length, group),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          t.channelName(notificationChannelId),
          channelDescription: t.channelDescription(notificationChannelId),
          importance: Importance.high,
          priority: Priority.high,
          groupKey: group,
          setAsGroupSummary: true,
          // The summary is a container, not news of its own. The default,
          // GroupAlertBehavior.all, alerts on top of the member just drawn —
          // so every grouped push buzzes twice.
          groupAlertBehavior: GroupAlertBehavior.children,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    ),
    'Could not draw the group summary for "$group"',
  );
}

/// Runs [action], logging rather than propagating a failure, and reporting
/// whether it succeeded.
///
/// Same idiom as `notification_reply.dart`'s `_attempt`, same reason: an
/// exception escaping here would be blamed on the notification already drawn.
/// [label] names the failing step.
Future<bool> _attempt(Future<void> Function() action, String label) async {
  try {
    await action();

    return true;
  } on Object catch (error) {
    debugPrint('$label: $error');

    return false;
  }
}
