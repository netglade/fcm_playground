import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Reads notification channels back from Android, and attempts to change one.
///
/// A port so the Channels page can be tested without a device. The plugin's own
/// `AndroidNotificationChannel` is the return type rather than an app-level
/// mirror: it is a plain data class with no platform calls in it, and every
/// property this page shows is already on it.
abstract class NotificationChannelReader {
  /// What the system currently holds, which is not necessarily what was asked
  /// for — see `bypassDnd`.
  Future<List<AndroidNotificationChannel>> read();

  /// Asks Android to give [id] a different [importance] by deleting the channel
  /// and recreating it under the same id.
  ///
  /// Not a plain `createNotificationChannel` call: the plugin's
  /// `AndroidNotificationChannel.toMap()` always sends `CreateIfNotExists`, and
  /// the Android side refuses that outright once a channel with the id already
  /// exists — the call would be discarded inside the plugin without ever
  /// reaching the platform, so "the importance did not change" would be true for
  /// the wrong reason and would prove nothing. Deleting first, then creating
  /// under the same id, is the only way this port's public surface can make
  /// Android actually answer the question.
  ///
  /// Expected to do nothing useful even so: Android documents that recreating a
  /// channel under an id it has seen before restores the settings that channel
  /// had at deletion, precisely to close off this kind of workaround. d7 exists
  /// to show that importance comes back unchanged regardless. The call is still
  /// made, because a demonstration nobody performs is a claim.
  Future<void> attemptImportanceChange(String id, Importance importance);
}
