import 'dart:typed_data';

import 'package:fcm_app/domains/notifications/app_notification_channel.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The channel group both chat channels are filed under.
///
/// d8: two channels appearing together in system settings, under one heading.
const chatChannelGroupId = 'chat';

/// The channel `d7` probes: its importance is asked to change, and the Channels
/// card shows the refusal.
///
/// One source of truth: `ChannelsCubit` and `ChannelCard` both need it.
const immutabilityProbeChannelId = 'chat_v1';

/// Every channel this app registers.
///
/// `final`, not `const`: `Int64List.fromList` is not a const constructor.
///
/// The first entry is the default, named in `AndroidManifest.xml` as FCM's
/// `default_notification_channel_id`. The rest serve a scenario that names them
/// in `android.notification.channel_id`.
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
  // d6, same lesson as d5: payload `vibrate_timings` cannot reach a channel
  // created without a pattern.
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
  // h2. The channel's half; the per-message category is set in
  // `notification_details_builder.dart`.
  const AppNotificationChannel(
    id: 'alarms',
    importance: Importance.high,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  ),
];

/// [channel] as the plugin's channel type.
///
/// The only place these nine fields are assembled, so a new field cannot reach
/// registration but miss the d7 probe. [importanceOverride] is for that probe.
///
/// No `enableVibration:` — passing `vibrationPattern != null` would kill
/// vibration on every patternless channel instead of leaving Android its
/// default buzz.
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
/// Null rather than the default, so a caller could tell "asked for a channel we
/// lack" from "asked for nothing". Both callers treat them the same today.
AppNotificationChannel? channelById(String? id) {
  if (id == null) return null;
  for (final channel in notificationChannels) {
    if (channel.id == id) return channel;
  }

  return null;
}

/// Creates the chat group and every channel in [notificationChannels].
///
/// Called from all three drawing isolates, and a no-op past the first: the
/// plugin refuses the call once a channel exists. So an install in Czech keeps
/// Czech channel names even after the app switches to English.
///
/// The group goes first — Android silently drops the grouping of a channel
/// whose group does not exist yet.
///
/// Reads copy through `t`, so the caller needs a locale set.
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
