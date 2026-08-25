import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/notification_content.dart';
import '../entities/notification_group_store.dart';
import 'shared_preferences_notification_group_store.dart';

/// [groups] with [messageId] recorded in [group], unchanged if it is already there.
///
/// Pure so the membership rule can be tested without a plugin: the posting around
/// it cannot be.
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
/// The group name is the sender's word and is used as given: the app has no way
/// to know its singular, and guessing one would be wrong more often than right.
String groupSummaryText(int count, String group) => '$count $group';

/// Records [message] in its group and redraws that group's summary.
///
/// Called by both drawing paths immediately after the notification itself is
/// drawn — the foreground presenter and the background isolate — so a summary
/// never appears in one state and not the other. The store and plugin are
/// injectable only so the two callers can share one instance each; there is no
/// test seam here, and the posting is covered by inspection and the manual
/// checklist.
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

  final groups = store ?? SharedPreferencesNotificationGroupStore();
  final updated = withMemberAdded(await groups.load(), group, message.id);
  await groups.save(updated);

  await (plugin ?? FlutterLocalNotificationsPlugin()).show(
    // Keyed on the group rather than a message, so the summary updates in place
    // as members arrive instead of stacking one row per notification.
    id: notificationIdFor(group),
    title: group,
    body: groupSummaryText(updated[group]!.length, group),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: group,
        setAsGroupSummary: true,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
}
