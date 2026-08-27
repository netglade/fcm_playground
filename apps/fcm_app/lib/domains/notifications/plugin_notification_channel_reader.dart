import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_channel_reader.dart';
import 'notification_channels.dart';

/// A [NotificationChannelReader] over `flutter_local_notifications`.
class PluginNotificationChannelReader implements NotificationChannelReader {
  PluginNotificationChannelReader(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// An empty list on a platform without channels, rather than a throw: the page
  /// then renders "not registered" for everything, which is the truth on iOS.
  @override
  Future<List<AndroidNotificationChannel>> read() async =>
      await _android?.getNotificationChannels() ?? const [];

  @override
  Future<void> attemptImportanceChange(String id, Importance importance) async {
    final requested = channelById(id);
    final android = _android;
    if (requested == null || android == null) {
      return;
    }

    // Deleting first is what makes this a real question rather than a no-op:
    // `createNotificationChannel` alone is discarded inside the plugin for a
    // channel that already exists, so the app would report "unchanged" without
    // ever having asked. Android documents that recreating a channel under an id
    // it has seen before restores the settings it had at deletion — a rule that
    // exists precisely to close this workaround — so the importance coming back
    // unchanged is Android's answer, not ours.
    await android.deleteNotificationChannel(channelId: id);
    await android.createNotificationChannel(
      toPluginChannel(requested, importanceOverride: importance),
    );
  }
}
