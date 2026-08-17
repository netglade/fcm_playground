import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_content.dart';
import 'notification_presenter.dart';

/// A [NotificationPresenter] over `flutter_local_notifications`.
///
/// Needed only for the foreground: while the app is backgrounded, FCM's own SDK
/// draws the tray entry, and on iOS a single presentation-options call is enough.
/// This exists because Android shows nothing for a message that arrives while
/// the app is in use.
class LocalNotificationPresenter implements NotificationPresenter {
  LocalNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            notificationChannelId,
            notificationChannelName,
            description: notificationChannelDescription,
            importance: Importance.high,
          ),
        );
  }

  @override
  Future<void> show(PushMessage message) => _plugin.show(
    id: notificationIdFor(message.id),
    title: message.title,
    body: message.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    // The payload is the message id, which is how a tap resolves back to a
    // message the inbox already holds.
    payload: message.id,
  );

  @override
  Future<void> dispose() => _taps.close();

  void _onResponse(NotificationResponse response) {
    if (response.payload case final id? when id.isNotEmpty) {
      _taps.add(id);
    }
  }
}
