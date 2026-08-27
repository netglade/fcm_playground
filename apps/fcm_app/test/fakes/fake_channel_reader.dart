import 'package:fcm_app/domains/notifications/notification_channel_reader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A reader whose answers the test dictates, and which records what it was asked.
class FakeChannelReader implements NotificationChannelReader {
  FakeChannelReader(this._channels);

  final List<AndroidNotificationChannel> _channels;
  final attempts = <(String, Importance)>[];
  Object? failWith;

  @override
  Future<List<AndroidNotificationChannel>> read() async {
    if (failWith case final error?) throw error;

    return _channels;
  }

  @override
  Future<void> attemptImportanceChange(String id, Importance importance) async {
    attempts.add((id, importance));
    // Android's actual behaviour: the request is accepted and the importance
    // does not move. The fake must not be kinder than the platform.
  }
}

AndroidNotificationChannel systemChannel(
  String id, {
  Importance importance = Importance.high,
  bool bypassDnd = false,
  AndroidNotificationSound? sound,
}) => AndroidNotificationChannel(
  id,
  'name',
  importance: importance,
  bypassDnd: bypassDnd,
  sound: sound,
);
