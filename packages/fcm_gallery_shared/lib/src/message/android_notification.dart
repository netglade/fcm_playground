import 'package:collection/collection.dart';

import 'android_notification_priority.dart';
import 'json_object_reader.dart';
import 'light_settings.dart';
import 'notification_proxy.dart';
import 'notification_visibility.dart';

/// FCM's `AndroidNotification`, nested under `Message.android.notification` —
/// everything Android's tray understands on top of, or in place of, the generic
/// `Message.notification`.
class AndroidNotification {
  const AndroidNotification({
    this.title,
    this.body,
    this.icon,
    this.color,
    this.sound,
    this.tag,
    this.clickAction,
    this.bodyLocKey,
    this.bodyLocArgs,
    this.titleLocKey,
    this.titleLocArgs,
    this.channelId,
    this.ticker,
    this.sticky,
    this.eventTime,
    this.localOnly,
    this.notificationPriority,
    this.defaultSound,
    this.defaultVibrateTimings,
    this.defaultLightSettings,
    this.vibrateTimings,
    this.visibility,
    this.notificationCount,
    this.lightSettings,
    this.image,
    this.bypassProxyNotification,
    this.proxy,
  });

  factory AndroidNotification.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'notification'));

  static AndroidNotification read(JsonObjectReader reader) {
    final notification = AndroidNotification(
      title: reader.text('title'),
      body: reader.text('body'),
      icon: reader.text('icon'),
      color: reader.text('color'),
      sound: reader.text('sound'),
      tag: reader.text('tag'),
      clickAction: reader.text('click_action'),
      bodyLocKey: reader.text('body_loc_key'),
      bodyLocArgs: reader.textList('body_loc_args'),
      titleLocKey: reader.text('title_loc_key'),
      titleLocArgs: reader.textList('title_loc_args'),
      channelId: reader.text('channel_id'),
      ticker: reader.text('ticker'),
      sticky: reader.flag('sticky'),
      eventTime: reader.text('event_time'),
      localOnly: reader.flag('local_only'),
      notificationPriority: reader.enumValue(
        'notification_priority',
        AndroidNotificationPriority.values,
        (value) => value.wireName,
      ),
      defaultSound: reader.flag('default_sound'),
      defaultVibrateTimings: reader.flag('default_vibrate_timings'),
      defaultLightSettings: reader.flag('default_light_settings'),
      vibrateTimings: reader.textList('vibrate_timings'),
      visibility: reader.enumValue(
        'visibility',
        NotificationVisibility.values,
        (value) => value.wireName,
      ),
      notificationCount: reader.integer('notification_count'),
      lightSettings: reader.object('light_settings', LightSettings.read),
      image: reader.text('image'),
      bypassProxyNotification: reader.flag('bypass_proxy_notification'),
      proxy: reader.enumValue(
        'proxy',
        NotificationProxy.values,
        (value) => value.wireName,
      ),
    );
    reader.requireNothingUnclaimed();

    return notification;
  }

  final String? title;

  final String? body;

  /// Names a drawable resource in the app, falling back to the app's own icon.
  final String? icon;

  /// `#rrggbb`.
  final String? color;

  /// Names a sound resource in the app.
  final String? sound;

  /// Reusing a tag replaces an existing notification rather than showing a second
  /// one alongside it.
  final String? tag;

  /// The action bundled into the tap intent, letting the app route to a screen.
  final String? clickAction;

  /// A key into the app's string resources, used to localise [body] on the device
  /// instead of shipping pre-translated text. The same goes for [titleLocKey].
  final String? bodyLocKey;

  final List<String>? bodyLocArgs;

  final String? titleLocKey;

  final List<String>? titleLocArgs;

  /// The channel the app registered, which controls the user-facing sound,
  /// importance and visibility Android applies.
  final String? channelId;

  /// Read aloud by accessibility services as the notification arrives.
  final String? ticker;

  /// Whether the notification survives being tapped, rather than dismissing
  /// itself.
  ///
  /// Not Android's ongoing flag, despite the name: a sticky notification is
  /// still swipeable. FCM has no field for a genuinely undismissable
  /// notification, which is why `f7_ongoing` is data-only and drawn by the app.
  final bool? sticky;

  /// A proto timestamp like `"2026-08-11T09:30:00Z"`, kept as text rather than
  /// parsed to [DateTime]: this model's contract is round-trip fidelity.
  final String? eventTime;

  /// Whether to hide the notification from wearables and other devices on the same
  /// account.
  final bool? localOnly;

  final AndroidNotificationPriority? notificationPriority;

  final bool? defaultSound;

  final bool? defaultVibrateTimings;

  final bool? defaultLightSettings;

  /// Proto durations like `["0.5s", "0.5s"]` alternating vibrate and pause, kept as
  /// text for the same reason as [eventTime].
  final List<String>? vibrateTimings;

  final NotificationVisibility? visibility;

  /// The launcher icon's badge count.
  final int? notificationCount;

  final LightSettings? lightSettings;

  /// A URL for FCM to download, never bytes.
  final String? image;

  /// Whether to bypass FCM's own proxying, taking [proxy] out of consideration.
  final bool? bypassProxyNotification;

  final NotificationProxy? proxy;

  Map<String, Object?> toJson() => {
    'title': ?title,
    'body': ?body,
    'icon': ?icon,
    'color': ?color,
    'sound': ?sound,
    'tag': ?tag,
    'click_action': ?clickAction,
    'body_loc_key': ?bodyLocKey,
    'body_loc_args': ?bodyLocArgs,
    'title_loc_key': ?titleLocKey,
    'title_loc_args': ?titleLocArgs,
    'channel_id': ?channelId,
    'ticker': ?ticker,
    'sticky': ?sticky,
    'event_time': ?eventTime,
    'local_only': ?localOnly,
    'notification_priority': ?notificationPriority?.wireName,
    'default_sound': ?defaultSound,
    'default_vibrate_timings': ?defaultVibrateTimings,
    'default_light_settings': ?defaultLightSettings,
    'vibrate_timings': ?vibrateTimings,
    'visibility': ?visibility?.wireName,
    'notification_count': ?notificationCount,
    'light_settings': ?lightSettings?.toJson(),
    'image': ?image,
    'bypass_proxy_notification': ?bypassProxyNotification,
    'proxy': ?proxy?.wireName,
  };

  static const _stringList = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is AndroidNotification &&
      title == other.title &&
      body == other.body &&
      icon == other.icon &&
      color == other.color &&
      sound == other.sound &&
      tag == other.tag &&
      clickAction == other.clickAction &&
      bodyLocKey == other.bodyLocKey &&
      _stringList.equals(bodyLocArgs, other.bodyLocArgs) &&
      titleLocKey == other.titleLocKey &&
      _stringList.equals(titleLocArgs, other.titleLocArgs) &&
      channelId == other.channelId &&
      ticker == other.ticker &&
      sticky == other.sticky &&
      eventTime == other.eventTime &&
      localOnly == other.localOnly &&
      notificationPriority == other.notificationPriority &&
      defaultSound == other.defaultSound &&
      defaultVibrateTimings == other.defaultVibrateTimings &&
      defaultLightSettings == other.defaultLightSettings &&
      _stringList.equals(vibrateTimings, other.vibrateTimings) &&
      visibility == other.visibility &&
      notificationCount == other.notificationCount &&
      lightSettings == other.lightSettings &&
      image == other.image &&
      bypassProxyNotification == other.bypassProxyNotification &&
      proxy == other.proxy;

  @override
  int get hashCode => Object.hashAll([
    title,
    body,
    icon,
    color,
    sound,
    tag,
    clickAction,
    bodyLocKey,
    ...?bodyLocArgs,
    titleLocKey,
    ...?titleLocArgs,
    channelId,
    ticker,
    sticky,
    eventTime,
    localOnly,
    notificationPriority,
    defaultSound,
    defaultVibrateTimings,
    defaultLightSettings,
    ...?vibrateTimings,
    visibility,
    notificationCount,
    lightSettings,
    image,
    bypassProxyNotification,
    proxy,
  ]);
}
