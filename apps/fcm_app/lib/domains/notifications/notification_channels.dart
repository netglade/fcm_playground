import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/app_notification_channel.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The id of the channel group both chat channels are filed under.
///
/// d8's demonstration: two channels that appear together in system settings,
/// under a heading of their own.
const chatChannelGroupId = 'chat';

/// The channel `d7` demonstrates on: importance is asked to change, and the
/// Channels page's card is where the refusal becomes visible.
///
/// The single source of truth for that id — `ChannelsCubit` and `ChannelCard`
/// both need it, and a copy in each is a copy that can drift out of step with
/// which channel actually carries the button.
const immutabilityProbeChannelId = 'chat_v1';

/// Every channel this app registers.
///
/// A `final` rather than a `const` list: `Int64List.fromList` is not a const
/// constructor, so `vibration_pattern` alone rules const out for the whole table.
///
/// The first entry is the app's default — the one `AndroidManifest.xml` names as
/// FCM's `default_notification_channel_id` — and everything after it exists for a
/// scenario that names it in `android.notification.channel_id`.
final List<AppNotificationChannel> notificationChannels = [
  const AppNotificationChannel(
    id: notificationChannelId,
    importance: Importance.high,
  ),
  // d1–d4: the four importances, which are the only thing that differs.
  const AppNotificationChannel(
    id: 'importance_high',
    importance: Importance.high,
  ),
  const AppNotificationChannel(
    id: 'importance_default',
    importance: Importance.defaultImportance,
  ),
  // Also i1_silent_no_sound: low is what "seen, not heard" means on Android O+.
  const AppNotificationChannel(
    id: 'importance_low',
    importance: Importance.low,
  ),
  const AppNotificationChannel(
    id: 'importance_min',
    importance: Importance.min,
  ),
  // d5. The sound is a channel property, not a payload one — which is the lesson.
  const AppNotificationChannel(
    id: 'custom_sound',
    importance: Importance.defaultImportance,
    sound: RawResourceAndroidNotificationSound('chime'),
  ),
  // d6. Same lesson as d5: `vibrate_timings` in the payload cannot reach a
  // channel that was created without a pattern.
  AppNotificationChannel(
    id: 'vibration_pattern',
    importance: Importance.defaultImportance,
    vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
  ),
  // d7 and d8. chat_v1 is the mistake, chat_v2 is the only fix Android allows.
  const AppNotificationChannel(
    id: 'chat_v1',
    importance: Importance.defaultImportance,
    groupId: chatChannelGroupId,
  ),
  const AppNotificationChannel(
    id: 'chat_v2',
    importance: Importance.high,
    groupId: chatChannelGroupId,
  ),
  // h1. Asked for; granted only with notification-policy access.
  const AppNotificationChannel(
    id: 'dnd_bypass',
    importance: Importance.high,
    bypassDnd: true,
  ),
  // h2. The alarm usage is the channel's half; the notification's category is
  // set per message in `notification_details_builder.dart`.
  const AppNotificationChannel(
    id: 'alarms',
    importance: Importance.high,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  ),
];

/// [channel] as the plugin's own channel type, ready for
/// `createNotificationChannel`.
///
/// The one place these nine fields are assembled — registration and the d7
/// probe both call this rather than each building an `AndroidNotificationChannel`
/// itself, so a field added to [AppNotificationChannel] cannot update one call
/// site and silently miss the other.
///
/// [importanceOverride] lets the d7 probe ask for a different importance than
/// [channel] itself carries, without needing a second channel to describe it.
///
/// No `enableVibration:` argument: the plugin defaults it to true, and passing
/// a computed value (say, `channel.vibrationPattern != null`) would disable
/// vibration outright on every channel with no pattern, rather than leaving it
/// to Android's own default buzz.
AndroidNotificationChannel toPluginChannel(
  AppNotificationChannel channel, {
  Importance? importanceOverride,
}) => AndroidNotificationChannel(
  channel.id,
  t.channelName(channel.id),
  description: t.channelDescription(channel.id),
  importance: importanceOverride ?? channel.importance,
  groupId: channel.groupId,
  sound: channel.sound,
  vibrationPattern: channel.vibrationPattern,
  bypassDnd: channel.bypassDnd,
  audioAttributesUsage: channel.audioAttributesUsage,
);

/// The channel used for anything that names no channel, or names one this app
/// does not have.
AppNotificationChannel get defaultNotificationChannel =>
    notificationChannels.first;

/// The channel [id] names, or null when it names none this app registers.
///
/// Null rather than the default, so a caller can tell "the payload asked for a
/// channel we do not have" from "the payload asked for nothing" if it ever needs
/// to. Today both callers treat them the same.
AppNotificationChannel? channelById(String? id) {
  if (id == null) return null;
  for (final channel in notificationChannels) {
    if (channel.id == id) return channel;
  }

  return null;
}

/// Creates the chat group and every channel in [notificationChannels].
///
/// Called from all three isolates that draw: the UI isolate's presenter, the
/// background-message isolate, and the reply-response isolate. A channel's name,
/// description and every other property are fixed the first time it is created —
/// `AndroidNotificationChannel.toMap()` always sends `CreateIfNotExists`, and the
/// plugin's Android side refuses the call outright once the channel already
/// exists (`canCreateNotificationChannel`,
/// `FlutterLocalNotificationsPlugin.java:483-492`). So calling this from three
/// isolates is a genuine no-op past the first: a fresh install in Czech gets
/// Czech channel names, and switching language afterwards does not rename a
/// channel that already exists.
///
/// The group goes first: Android drops the grouping of a channel filed under a
/// group that does not exist yet, silently.
///
/// Reads the copy through `t`, so the caller must have a locale set — see
/// `restoreStoredLocale` for the two isolates where that is not automatic.
Future<void> registerNotificationChannels(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android == null) {
    return;
  }

  await android.createNotificationChannelGroup(
    AndroidNotificationChannelGroup(chatChannelGroupId, t.chatChannelGroupName),
  );

  for (final channel in notificationChannels) {
    await android.createNotificationChannel(toPluginChannel(channel));
  }
}
