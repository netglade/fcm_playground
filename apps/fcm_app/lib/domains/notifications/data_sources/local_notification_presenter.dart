import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../push/entities/push_tap.dart';
import '../entities/notification_content.dart';
import '../entities/notification_presenter.dart';
import 'notification_details_builder.dart';

/// A [NotificationPresenter] over `flutter_local_notifications`, needed only
/// because Android shows nothing for a message that arrives while the app is in
/// use.
class LocalNotificationPresenter implements NotificationPresenter {
  LocalNotificationPresenter({
    FlutterLocalNotificationsPlugin? plugin,
    AppLifecycleState Function()? lifecycleState,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _lifecycleState = lifecycleState ?? _bindingLifecycleState;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Injected so the tests can say which state a press arrived in. There is no
  /// other way to drive `WidgetsBinding`'s lifecycle from a unit test.
  final AppLifecycleState Function() _lifecycleState;

  // Single-subscription, not broadcast: initialize() emits the launching press
  // before anything subscribes, and a broadcast controller discards events added
  // while nothing is listening. Each is consumed by exactly one subscriber
  // either way, so single-subscription costs nothing.
  final _taps = StreamController<PushTap>();
  final _dismissals = StreamController<String>();

  /// The press that launched the app, remembered only until the next response.
  ///
  /// The plugin documents `getNotificationAppLaunchDetails` as the route for a
  /// notification that started the process and `onDidReceiveNotificationResponse`
  /// as the route for one pressed while it was already running — but on Android
  /// the callback has been observed firing for the launching press as well. Two
  /// `opened` events for one press would be a telemetry bug, so the first
  /// response matching this is dropped.
  ({String id, String? actionId})? _launchResponse;

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

    // Last, so the channel exists and both streams are live before a press that
    // started the process is announced on them.
    handleLaunchDetails(await _plugin.getNotificationAppLaunchDetails());
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
    // Not awaited: a single-subscription controller's close() future only
    // completes once a listener has received the done event, and dispose can run
    // before anything ever subscribes. Closing still stops further adds.
    unawaited(_taps.close());
    unawaited(_dismissals.close());
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

      // Consumed by the first response either way: only the echo of the
      // launching press is suppressed, so pressing the same button again a
      // moment later still counts.
      if (_launchResponse case final launch?) {
        _launchResponse = null;
        if (launch.id == id && launch.actionId == response.actionId) {
          return;
        }
      }

      // The state has to be read, not assumed: since the background isolate
      // draws through the same builder, a press can reach this callback with the
      // app off screen.
      final from = _lifecycleState() == AppLifecycleState.resumed
          ? OpenedFrom.foreground
          : OpenedFrom.background;
      _taps.add(PushTap(id, from, actionId: response.actionId));
    }
  }

  /// Reports the press that started the process, if one did.
  ///
  /// Called once from [initialize]. The mirror of `FirebasePushSource`'s
  /// `getInitialMessage()` — and the only route for these scenarios, because a
  /// data-only payload never reaches `getInitialMessage` at all.
  ///
  /// Visible for testing because the plugin supplies the details through a
  /// method there is otherwise no way to drive.
  @visibleForTesting
  void handleLaunchDetails(NotificationAppLaunchDetails? details) {
    if (details == null || !details.didNotificationLaunchApp) {
      return;
    }

    final response = details.notificationResponse;
    final id = response?.payload;
    if (response == null || id == null || id.isEmpty) {
      return;
    }

    _launchResponse = (id: id, actionId: response.actionId);
    _taps.add(PushTap(id, OpenedFrom.killed, actionId: response.actionId));
  }
}

/// The binding's view of the app state, defaulting to resumed.
///
/// Null before the first lifecycle event reaches the binding. Foreground is the
/// honest reading there: it is what this presenter claimed unconditionally until
/// now, and an unknown state must not fabricate a background open.
AppLifecycleState _bindingLifecycleState() =>
    WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
