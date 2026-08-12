import 'package:collection/collection.dart';

import 'android_notification_priority.dart';
import 'json_object_reader.dart';
import 'light_settings.dart';
import 'notification_proxy.dart';
import 'notification_visibility.dart';

/// The Android-specific rendering of a notification.
///
/// FCM's `AndroidNotification`, nested under `Message.android.notification`.
/// Everything here is Android's own on top of, or in place of, the generic
/// `Message.notification` — icon, colour, channel, priority and the rest of
/// what the platform's notification tray understands.
class AndroidNotification {
  /// Creates an Android notification, leaving unset fields for FCM and the
  /// client app to fall back on.
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

  /// Reads FCM's `AndroidNotification` object.
  factory AndroidNotification.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'notification'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
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

  /// The notification's headline, shown in the tray.
  final String? title;

  /// The notification's text, shown below the title.
  final String? body;

  /// The name of a drawable resource in the app to use as the small icon,
  /// falling back to the app's own icon when unset.
  final String? icon;

  /// The notification's accent colour, as a `#rrggbb` string.
  final String? color;

  /// The name of a sound resource in the app to play on delivery.
  final String? sound;

  /// A tag that, when reused, replaces an existing notification rather than
  /// showing a second one alongside it.
  final String? tag;

  /// The action bundled into the intent fired when the user taps the
  /// notification, letting the app route to a specific screen.
  final String? clickAction;

  /// A key into the app's string resources, used to localise [body] on the
  /// device instead of shipping pre-translated text.
  final String? bodyLocKey;

  /// The arguments substituted into [bodyLocKey]'s format string.
  final List<String>? bodyLocArgs;

  /// A key into the app's string resources, used to localise [title] on the
  /// device instead of shipping pre-translated text.
  final String? titleLocKey;

  /// The arguments substituted into [titleLocKey]'s format string.
  final List<String>? titleLocArgs;

  /// The notification channel the app registered to receive this
  /// notification, controlling the user-facing settings — sound, importance,
  /// visibility — that Android applies to it.
  final String? channelId;

  /// Text read aloud by accessibility services and shown in the status bar
  /// as the notification arrives.
  final String? ticker;

  /// Whether the notification stays in the tray until the user acts on it,
  /// rather than being dismissable with a swipe.
  final bool? sticky;

  /// When the event that triggered the notification occurred, as a proto
  /// timestamp like `"2026-08-11T09:30:00Z"`.
  ///
  /// Kept as text rather than parsed to [DateTime]: this model's contract is
  /// round-trip fidelity, not a particular timestamp representation.
  final String? eventTime;

  /// Whether the notification is only relevant to this device, hiding it
  /// from wearables and other devices signed into the same account.
  final bool? localOnly;

  /// How prominently Android displays the notification once delivered.
  final AndroidNotificationPriority? notificationPriority;

  /// Whether to use the notification channel's default sound rather than
  /// [sound].
  final bool? defaultSound;

  /// Whether to use the notification channel's default vibration pattern
  /// rather than [vibrateTimings].
  final bool? defaultVibrateTimings;

  /// Whether to use the notification channel's default LED settings rather
  /// than [lightSettings].
  final bool? defaultLightSettings;

  /// The vibration pattern, as proto durations like `["0.5s", "0.5s"]`
  /// alternating vibrate and pause.
  ///
  /// Kept as text for the same reason as [eventTime].
  final List<String>? vibrateTimings;

  /// Whether the notification content shows on a locked screen.
  final NotificationVisibility? visibility;

  /// The number shown as the launcher icon's badge count.
  final int? notificationCount;

  /// How Android should flash the device's notification LED.
  final LightSettings? lightSettings;

  /// URL of an image for FCM to download and display — a URL, never bytes.
  final String? image;

  /// Whether to bypass FCM's own proxying of the notification, taking
  /// [proxy] out of consideration.
  final bool? bypassProxyNotification;

  /// Whether Android may proxy the notification.
  final NotificationProxy? proxy;

  /// Serialises to FCM's `AndroidNotification` shape, omitting unset fields.
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
