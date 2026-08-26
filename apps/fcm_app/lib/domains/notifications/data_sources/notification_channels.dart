import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/notification_content.dart';

/// The id of the channel group both chat channels are filed under.
///
/// d8's demonstration: two channels that appear together in system settings,
/// under a heading of their own.
const chatChannelGroupId = 'chat';

/// One Android notification channel, as this app asks for it.
///
/// Name and description are absent on purpose: Android shows both to the user in
/// system settings, so they are localized and cannot be const. Registration reads
/// them from the translations by [id]. See `channel_text.dart`.
class AppNotificationChannel {
  const AppNotificationChannel({
    required this.id,
    required this.importance,
    this.groupId,
    this.sound,
    this.vibrationPattern,
    this.bypassDnd = false,
    this.audioAttributesUsage = AudioAttributesUsage.notification,
  });

  final String id;
  final Importance importance;
  final String? groupId;
  final AndroidNotificationSound? sound;
  final Int64List? vibrationPattern;

  /// Requested, not granted. Android drops this to false unless the user has
  /// given the app notification-policy access, which is what h1 exists to show.
  final bool bypassDnd;

  final AudioAttributesUsage audioAttributesUsage;
}

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
  const AppNotificationChannel(id: 'importance_low', importance: Importance.low),
  const AppNotificationChannel(id: 'importance_min', importance: Importance.min),
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
