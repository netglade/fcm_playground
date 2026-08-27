import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
