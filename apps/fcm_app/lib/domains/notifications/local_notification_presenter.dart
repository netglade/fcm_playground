import 'dart:async';

import 'package:fcm_app/domains/notifications/notification_channels.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/notifications/notification_details_builder.dart';
import 'package:fcm_app/domains/notifications/notification_images.dart';
import 'package:fcm_app/domains/notifications/notification_group_store.dart';
import 'package:fcm_app/domains/notifications/notification_group_summary.dart';
import 'package:fcm_app/domains/notifications/notification_presenter.dart';
import 'package:fcm_app/domains/notifications/notification_reply.dart';
import 'package:fcm_app/domains/notifications/shared_preferences_notification_group_store.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A [NotificationPresenter] over `flutter_local_notifications`, needed because
/// Android draws nothing for a push arriving while the app is on screen.
class LocalNotificationPresenter implements NotificationPresenter {
  LocalNotificationPresenter({
    FlutterLocalNotificationsPlugin? plugin,
    AppLifecycleState Function()? lifecycleState,
    NotificationGroupStore? groups,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _lifecycleState = lifecycleState ?? _bindingLifecycleState,
       _groups = groups ?? SharedPreferencesNotificationGroupStore();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Injected so tests can say which state a press arrived in — there is no
  /// other way to drive `WidgetsBinding`'s lifecycle from a unit test.
  final AppLifecycleState Function() _lifecycleState;

  /// The store [postGroupSummary] writes to, so [clearAll] can forget it too.
  final NotificationGroupStore _groups;

  // Single-subscription, not broadcast: initialize() emits the launching press
  // before anything subscribes, and a broadcast controller would discard it.
  // Each has exactly one subscriber anyway.
  final _taps = StreamController<PushTap>();
  final _dismissals = StreamController<String>();

  /// The press that launched the app, remembered only until the next response.
  ///
  /// Insurance, not a fix for an observed bug: the pinned plugin version reports
  /// a launching press through one route only. Should a future version deliver
  /// it through both, two `opened` events for one press would be a telemetry
  /// bug, so the first matching response is dropped however late it arrives.
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
      onDidReceiveBackgroundNotificationResponse: onNotificationReply,
    );

    await registerNotificationChannels(_plugin);

    // Last, so the channel exists and both streams are live before a launching
    // press is announced on them.
    //
    // Caught locally: a throw would reach `_startPresenter`, which answers any
    // `initialize()` failure by swapping in a silent presenter — no banners for
    // the whole session. An unreadable launch press is one lost tap, not that.
    try {
      handleLaunchDetails(await _plugin.getNotificationAppLaunchDetails());
    } on Object catch (error) {
      debugPrint('Could not read the launch details: $error');
    }
  }

  @override
  Future<void> show(PushMessage message) async {
    // Fetched before the draw, and a no-op for every style that needs no
    // image — so only `big_picture` and `large_icon` ever wait on a network.
    final images = await loadNotificationImages(message);

    await _plugin.show(
      id: notificationIdOf(message),
      title: message.title,
      body: message.body,
      notificationDetails: buildNotificationDetails(
        message,
        picture: images.picture,
        largeIcon: images.largeIcon,
      ),
      // The message id — how a tap resolves back to a held message.
      payload: message.id,
    );
    await postGroupSummary(message, plugin: _plugin, store: _groups);
  }

  @override
  Future<void> clearAll() async {
    // Plugin first: if it throws, the store still describes what the tray
    // shows.
    await _plugin.cancelAll();
    await _groups.clear();
  }

  @override
  Future<void> dispose() async {
    // Unawaited: close() only completes once a listener takes the done event,
    // and dispose can run before anything subscribes. It still stops adds.
    unawaited(_taps.close());
    unawaited(_dismissals.close());
  }

  /// Routes one plugin response to the stream it belongs on.
  ///
  /// Visible for testing: the tap/dismissal distinction lives here, and the
  /// plugin only supplies it through an uninvokable callback.
  @visibleForTesting
  void handleResponse(NotificationResponse response) {
    if (response.payload case final id? when id.isNotEmpty) {
      if (response.notificationResponseType ==
          NotificationResponseType.notificationDismissed) {
        _dismissals.add(id);

        return;
      }

      // A one-shot check on `(id, actionId)`, not on timing, so the first
      // matching response is consumed whenever it arrives. In practice that is
      // only ever the echo, since `cancelNotification: true` makes a genuine
      // re-press nearly unreachable.
      if (_launchResponse case final launch?) {
        _launchResponse = null;
        if (launch.id == id && launch.actionId == response.actionId) {
          return;
        }
      }

      // Read, not assumed: the background isolate draws through the same
      // builder, so a press can arrive with the app off screen.
      final from = _lifecycleState() == AppLifecycleState.resumed
          ? OpenedFrom.foreground
          : OpenedFrom.background;
      _taps.add(PushTap(id, from, actionId: response.actionId));
    }
  }

  /// Reports the press that started the process, if one did.
  ///
  /// Called once from [initialize]. Mirrors `FirebasePushSource`'s
  /// `getInitialMessage()`, and is the only route for a data-only payload, which
  /// never reaches that method at all.
  ///
  /// Visible for testing: the plugin supplies the details through an undrivable
  /// method.
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
/// Null before the first lifecycle event. Foreground is the honest reading: an
/// unknown state must not fabricate a background open.
AppLifecycleState _bindingLifecycleState() =>
    WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
