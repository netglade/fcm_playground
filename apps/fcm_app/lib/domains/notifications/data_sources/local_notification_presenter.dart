import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../push/entities/push_tap.dart';
import '../entities/notification_content.dart';
import '../entities/notification_presenter.dart';
import 'notification_details_builder.dart';

/// A [NotificationPresenter] over `flutter_local_notifications`, needed only
/// because Android shows nothing for a message that arrives while the app is in
/// use.
class LocalNotificationPresenter implements NotificationPresenter {
  LocalNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<PushTap>.broadcast();
  final _dismissals = StreamController<String>.broadcast();

  @override
  Stream<PushTap> get taps => _taps.stream;

  @override
  Stream<String> get dismissals => _dismissals.stream;

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: handleResponse,
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
    notificationDetails: buildNotificationDetails(message),
    // The payload is the message id, which is how a tap resolves back to a
    // message the inbox already holds.
    payload: message.id,
  );

  @override
  Future<void> dispose() async {
    await _taps.close();
    await _dismissals.close();
  }

  /// Routes one plugin response to the stream it belongs on.
  ///
  /// Visible for testing because this is where the tap/dismissal distinction lives, and
  /// the plugin hands it to us through a callback there is otherwise no way to invoke.
  @visibleForTesting
  void handleResponse(NotificationResponse response) {
    if (response.payload case final id? when id.isNotEmpty) {
      if (response.notificationResponseType ==
          NotificationResponseType.notificationDismissed) {
        _dismissals.add(id);

        return;
      }
      // Always foreground: this presenter only ever draws a banner for a message that
      // arrived while the app was on screen.
      _taps.add(PushTap(id, OpenedFrom.foreground));
    }
  }
}
