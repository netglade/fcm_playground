import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fcm_notification_form.dart';
import 'light_settings_form.dart';

/// Edits `android.notification` — everything Android's notification tray
/// understands on top of, or in place of, the cross-platform block.
///
/// The largest form in the set: 27 fields, mirroring [AndroidNotification]
/// one-for-one so the mapping in both directions stays mechanical and testable
/// without pumping a widget.
///
/// FCM requires nothing here, so every input is optional and [toModel] returns
/// null while the whole block is untouched — the payload then omits
/// `"notification": {}` rather than sending it.
class AndroidNotificationForm extends GladeModel {
  /// The notification's headline, shown in the tray.
  late GladeStringInput title;

  /// The notification's text, shown below the title.
  late GladeStringInput body;

  /// Names a drawable resource in the app; unset falls back to the app icon.
  late GladeStringInput icon;

  /// The accent colour Android tints the notification with, as `#rrggbb`.
  late GladeStringInput color;

  /// Names a sound resource in the app for Android to play on delivery.
  late GladeStringInput sound;

  /// Reusing a tag replaces the existing notification instead of stacking a
  /// second one beside it.
  late GladeStringInput tag;

  /// The action bundled into the tap intent, letting the app route to a screen.
  late GladeStringInput clickAction;

  /// A key into the app's string resources, so the device localises the body
  /// rather than the sender shipping translated text.
  late GladeStringInput bodyLocKey;

  /// The arguments substituted into [bodyLocKey]'s format string.
  late GladeInput<List<String>?> bodyLocArgs;

  /// A key into the app's string resources, localising the title on device.
  late GladeStringInput titleLocKey;

  /// The arguments substituted into [titleLocKey]'s format string.
  late GladeInput<List<String>?> titleLocArgs;

  /// The channel the app registered, which decides the user-facing sound,
  /// importance and lock-screen behaviour Android applies.
  late GladeStringInput channelId;

  /// Text read aloud by accessibility services as the notification arrives.
  late GladeStringInput ticker;

  /// Whether the notification stays until the user acts, rather than being
  /// swipeable away.
  late GladeInput<bool?> sticky;

  /// When the triggering event happened, as a proto timestamp — text, because
  /// round-trip fidelity matters more than a parsed representation.
  late GladeStringInput eventTime;

  /// Whether to keep the notification off wearables and other devices on the
  /// same account.
  late GladeInput<bool?> localOnly;

  /// How prominently Android displays the notification once delivered.
  late GladeInput<AndroidNotificationPriority?> notificationPriority;

  /// Whether to use the channel's default sound rather than [sound].
  late GladeInput<bool?> defaultSound;

  /// Whether to use the channel's default vibration rather than
  /// [vibrateTimings].
  late GladeInput<bool?> defaultVibrateTimings;

  /// Whether to use the channel's default LED settings rather than
  /// [lightSettings].
  late GladeInput<bool?> defaultLightSettings;

  /// The vibration pattern, as proto durations alternating vibrate and pause.
  late GladeInput<List<String>?> vibrateTimings;

  /// How much of the notification a locked screen shows.
  late GladeInput<NotificationVisibility?> visibility;

  /// The number Android shows as the launcher icon's badge count.
  late GladeInput<int?> notificationCount;

  /// How Android should flash the device's notification LED.
  ///
  /// A nested model rather than four more inputs, because FCM requires every
  /// one of its fields once the block is present — see [LightSettingsForm].
  late LightSettingsForm lightSettings;

  /// URL of an image for FCM to download and display — a URL, never bytes.
  late GladeStringInput image;

  /// Whether to bypass FCM's own proxying, taking [proxy] out of consideration.
  late GladeInput<bool?> bypassProxyNotification;

  /// Whether Android may proxy the notification.
  late GladeInput<NotificationProxy?> proxy;

  @override
  List<GladeInput<Object?>> get inputs => [
    title,
    body,
    icon,
    color,
    sound,
    tag,
    clickAction,
    bodyLocKey,
    bodyLocArgs,
    titleLocKey,
    titleLocArgs,
    channelId,
    ticker,
    sticky,
    eventTime,
    localOnly,
    notificationPriority,
    defaultSound,
    defaultVibrateTimings,
    defaultLightSettings,
    vibrateTimings,
    visibility,
    notificationCount,
    image,
    bypassProxyNotification,
    proxy,
  ];

  @override
  void initialize() {
    title = _text('title');
    body = _text('body');
    icon = _text('icon');
    color = GladeStringInput(
      inputKey: 'android.notification.color',
      isRequired: false,
      validator: (validator) =>
          (validator..match(
                // Anchored on purpose: match() calls hasMatch, so an unanchored
                // pattern would accept 'blue #ff0000 ish'.
                pattern: r'^#[0-9a-fA-F]{6}$',
                // An empty field is absent, not invalid. Without this the regex
                // runs on '' and an untouched form blocks Send.
                shouldValidate: (value) => value.isNotEmpty,
                devMessage: (_) => 'must be #rrggbb',
              ))
              .build(),
    );
    sound = _text('sound');
    tag = _text('tag');
    clickAction = _text('click_action');
    bodyLocKey = _text('body_loc_key');
    bodyLocArgs = _stringList('body_loc_args');
    titleLocKey = _text('title_loc_key');
    titleLocArgs = _stringList('title_loc_args');
    channelId = _text('channel_id');
    ticker = _text('ticker');
    sticky = _flag('sticky');
    eventTime = _text('event_time');
    localOnly = _flag('local_only');
    notificationPriority = _choice('notification_priority');
    defaultSound = _flag('default_sound');
    defaultVibrateTimings = _flag('default_vibrate_timings');
    defaultLightSettings = _flag('default_light_settings');
    // .create rather than .optional: it is the one collection with a validator,
    // and .optional hard-codes an empty one internally.
    vibrateTimings = GladeInput<List<String>?>.create(
      inputKey: 'android.notification.vibrate_timings',
      value: null,
      validator: (validator) =>
          (validator..satisfy(
                // Null and empty pass: an unset pattern is absent rather than
                // invalid, so an untouched form stays valid.
                (value) =>
                    value == null ||
                    value.every(
                      (entry) => RegExp(r'^\d+(\.\d+)?s$').hasMatch(entry),
                    ),
                devMessage: (_) => 'each entry must be a duration such as 0.5s',
              ))
              .build(),
    );
    visibility = _choice('visibility');
    notificationCount = GladeIntInputNullable(
      inputKey: 'android.notification.notification_count',
      useTextEditingController: true,
      // The default converter treats '' as unparseable and keeps the previous
      // value, so clearing the field would still send the old number.
      stringToValueConverter: StringToTypeConverter<int?>(
        converter: (raw, _) =>
            (raw == null || raw.trim().isEmpty) ? null : int.parse(raw),
        converterBack: (value) => value?.toString() ?? '',
      ),
    );
    lightSettings = LightSettingsForm();
    image = _text('image');
    bypassProxyNotification = _flag('bypass_proxy_notification');
    proxy = _choice('proxy');
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(AndroidNotification? source) {
    title.updateValue(source?.title ?? '');
    body.updateValue(source?.body ?? '');
    icon.updateValue(source?.icon ?? '');
    color.updateValue(source?.color ?? '');
    sound.updateValue(source?.sound ?? '');
    tag.updateValue(source?.tag ?? '');
    clickAction.updateValue(source?.clickAction ?? '');
    bodyLocKey.updateValue(source?.bodyLocKey ?? '');
    bodyLocArgs.updateValue(source?.bodyLocArgs);
    titleLocKey.updateValue(source?.titleLocKey ?? '');
    titleLocArgs.updateValue(source?.titleLocArgs);
    channelId.updateValue(source?.channelId ?? '');
    ticker.updateValue(source?.ticker ?? '');
    sticky.updateValue(source?.sticky);
    eventTime.updateValue(source?.eventTime ?? '');
    localOnly.updateValue(source?.localOnly);
    notificationPriority.updateValue(source?.notificationPriority);
    defaultSound.updateValue(source?.defaultSound);
    defaultVibrateTimings.updateValue(source?.defaultVibrateTimings);
    defaultLightSettings.updateValue(source?.defaultLightSettings);
    vibrateTimings.updateValue(source?.vibrateTimings);
    visibility.updateValue(source?.visibility);
    notificationCount.updateValue(source?.notificationCount);
    lightSettings.readFrom(source?.lightSettings);
    image.updateValue(source?.image ?? '');
    bypassProxyNotification.updateValue(source?.bypassProxyNotification);
    proxy.updateValue(source?.proxy);
  }

  /// The block as FCM's own model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"notification": {}`. "Is anything set?"
  /// is asked by comparing against the empty instance, which cannot drift out of
  /// step as fields are added — the typed classes have value equality precisely
  /// so this works.
  AndroidNotification? toModel() {
    final result = AndroidNotification(
      title: emptyMeansAbsent(title.value),
      body: emptyMeansAbsent(body.value),
      icon: emptyMeansAbsent(icon.value),
      color: emptyMeansAbsent(color.value),
      sound: emptyMeansAbsent(sound.value),
      tag: emptyMeansAbsent(tag.value),
      clickAction: emptyMeansAbsent(clickAction.value),
      bodyLocKey: emptyMeansAbsent(bodyLocKey.value),
      bodyLocArgs: _absentIfEmpty(bodyLocArgs.value),
      titleLocKey: emptyMeansAbsent(titleLocKey.value),
      titleLocArgs: _absentIfEmpty(titleLocArgs.value),
      channelId: emptyMeansAbsent(channelId.value),
      ticker: emptyMeansAbsent(ticker.value),
      sticky: sticky.value,
      eventTime: emptyMeansAbsent(eventTime.value),
      localOnly: localOnly.value,
      notificationPriority: notificationPriority.value,
      defaultSound: defaultSound.value,
      defaultVibrateTimings: defaultVibrateTimings.value,
      defaultLightSettings: defaultLightSettings.value,
      vibrateTimings: _absentIfEmpty(vibrateTimings.value),
      visibility: visibility.value,
      notificationCount: notificationCount.value,
      lightSettings: lightSettings.toModel(),
      image: emptyMeansAbsent(image.value),
      bypassProxyNotification: bypassProxyNotification.value,
      proxy: proxy.value,
    );

    return result == const AndroidNotification() ? null : result;
  }
}

/// One of FCM's optional strings in this block, none of which it requires.
///
/// `isRequired: false` on every one — `GladeStringInput` defaults to required,
/// and missing this on a single input would leave the whole form invalid until
/// that field was filled.
GladeStringInput _text(String name) =>
    GladeStringInput(inputKey: 'android.notification.$name', isRequired: false);

/// One of FCM's optional flags, which needs three states rather than two.
///
/// `GladeBoolInput` is a `GladeInput<bool>` and cannot hold null, so it could
/// not tell "the user chose false" from "the user chose nothing" — and a form
/// that cannot say "absent" would send fields nobody set.
GladeInput<bool?> _flag(String name) => GladeInput<bool?>.optional(
  inputKey: 'android.notification.$name',
  value: null,
);

/// One of FCM's optional enums, held nullable so "not set" stays expressible.
GladeInput<E?> _choice<E extends Enum>(String name) => GladeInput<E?>.optional(
  inputKey: 'android.notification.$name',
  value: null,
);

/// One of FCM's optional string lists, with no rule beyond being a list.
///
/// Typed over the whole collection so the row editor can hand back a list and
/// `updateValue` takes it like any other value. Holding these outside `inputs`
/// would put them outside glade's validity and dirty tracking, leaving
/// `toModel` the only thing that knew they existed.
GladeInput<List<String>?> _stringList(String name) =>
    GladeInput<List<String>?>.optional(
      inputKey: 'android.notification.$name',
      value: null,
    );

/// An empty list means the field is absent, as an empty string does.
///
/// Deleting every row of a list editor leaves `[]`, and sending
/// `"vibrate_timings": []` would ask Android for an empty vibration pattern
/// rather than for its default.
List<String>? _absentIfEmpty(List<String>? value) =>
    (value == null || value.isEmpty) ? null : value;
