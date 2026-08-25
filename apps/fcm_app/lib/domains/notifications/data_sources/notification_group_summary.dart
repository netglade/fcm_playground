import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
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
/// never appears in one state and not the other. [plugin] is injectable so each
/// caller can pass the instance already initialised in its own isolate, and both
/// do; [store] is injectable for the same shape, but neither caller passes one —
/// there is no test seam here, and the posting is covered by inspection and the
/// manual checklist.
///
/// A summary is a convenience over the notification it accompanies, not the
/// notification itself, so every fallible step here — loading the group store,
/// saving it, drawing the summary row — is caught and logged rather than left to
/// throw. Both callers await [message]'s own notification before this runs, and
/// both treat any exception from the function they call as proof that nothing
/// was drawn, skipping the `displayed` telemetry event for a notification that
/// in fact appeared. Letting a failure here escape would make this function's
/// own trouble look like that notification's trouble.
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
    // Nothing to add the message to and no known count to show, so there is
    // nothing safe left for this call to do.
    return;
  }

  final updated = withMemberAdded(loaded, group, message.id);

  await _attempt(
    () => groupStore.save(updated),
    'Could not save notification groups while posting the summary for "$group"',
  );

  await _attempt(
    // The saved count and the drawn count can disagree if the save above just
    // failed — drawing from [updated] regardless is still the best answer this
    // call can give, and the next member to arrive will resave the true count.
    () => (plugin ?? FlutterLocalNotificationsPlugin()).show(
      // Keyed on the group rather than a message, so the summary updates in
      // place as members arrive instead of stacking one row per notification.
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
    ),
    'Could not draw the group summary for "$group"',
  );
}

/// Runs [action], logging rather than propagating a failure, and reporting
/// whether it succeeded.
///
/// The same idiom `notification_reply.dart`'s `_attempt` uses in the
/// neighbouring isolate, for the same reason: [postGroupSummary] runs after the
/// message's own notification has already been drawn, and an exception left to
/// escape from here would be blamed on that notification instead of on the
/// summary step that actually failed. [label] names the step, so the log line
/// says which one without the caller having to repeat it.
Future<bool> _attempt(Future<void> Function() action, String label) async {
  try {
    await action();

    return true;
  } on Object catch (error) {
    debugPrint('$label: $error');

    return false;
  }
}
