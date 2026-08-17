import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'fcm_notification_form.dart';
import 'light_settings_form.dart';

/// Edits `android.notification` — everything Android's notification tray
/// understands on top of, or in place of, the cross-platform block.
///
/// Mirrors [AndroidNotification] one-for-one. FCM requires nothing here, so every
/// input is optional and [toModel] returns null while the whole block is
/// untouched.
class AndroidNotificationForm extends GladeModel {
  late GladeStringInput title;

  late GladeStringInput body;

  late GladeStringInput icon;

  late GladeStringInput color;

  late GladeStringInput sound;

  /// Reusing a tag replaces the existing notification instead of stacking a
  /// second one beside it.
  late GladeStringInput tag;

  late GladeStringInput clickAction;

  /// A key into the app's string resources, so the device localises the body
  /// rather than the sender shipping translated text.
  late GladeStringInput bodyLocKey;

  late GladeInput<List<String>?> bodyLocArgs;

  late GladeStringInput titleLocKey;

  late GladeInput<List<String>?> titleLocArgs;

  late GladeStringInput channelId;

  late GladeStringInput ticker;

  late GladeInput<bool?> sticky;

  /// A proto timestamp — text, because round-trip fidelity matters more than a
  /// parsed representation.
  late GladeStringInput eventTime;

  late GladeInput<bool?> localOnly;

  late GladeInput<AndroidNotificationPriority?> notificationPriority;

  late GladeInput<bool?> defaultSound;

  late GladeInput<bool?> defaultVibrateTimings;

  late GladeInput<bool?> defaultLightSettings;

  /// Proto durations alternating vibrate and pause.
  late GladeInput<List<String>?> vibrateTimings;

  late GladeInput<NotificationVisibility?> visibility;

  late GladeInput<int?> notificationCount;

  /// A nested model rather than four more inputs, because FCM requires every one
  /// of its fields once the block is present — see [LightSettingsForm].
  late LightSettingsForm lightSettings;

  /// A URL for FCM to download, never bytes.
  late GladeStringInput image;

  late GladeInput<bool?> bypassProxyNotification;

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

  /// This form and every model beneath it — see `FcmMessageForm.allModels` for
  /// why the whole tree has to be listened to rather than just the root.
  List<GladeModelBase> get allModels => [this, ...lightSettings.allModels];

  /// Whether every input here and in the nested block is valid.
  ///
  /// [lightSettings]' inputs are deliberately absent from [inputs] —
  /// `initialize()` would bind them to *this* model — so the nested block escapes
  /// the inherited getter and has to be folded back in. It composes at every
  /// level because `FormSection`'s badge is per section: a green badge on
  /// `android.notification` hiding a red one inside a closed `light_settings` is
  /// exactly what the badge exists to prevent.
  @override
  bool get isValid => super.isValid && lightSettings.isValid;

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
  /// "Is anything set?" is asked by comparing against the empty instance, which
  /// cannot drift out of step as fields are added — the typed classes have value
  /// equality precisely so this works.
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
      bodyLocArgs: absentIfEmptyList(bodyLocArgs.value),
      titleLocKey: emptyMeansAbsent(titleLocKey.value),
      titleLocArgs: absentIfEmptyList(titleLocArgs.value),
      channelId: emptyMeansAbsent(channelId.value),
      ticker: emptyMeansAbsent(ticker.value),
      sticky: sticky.value,
      eventTime: emptyMeansAbsent(eventTime.value),
      localOnly: localOnly.value,
      notificationPriority: notificationPriority.value,
      defaultSound: defaultSound.value,
      defaultVibrateTimings: defaultVibrateTimings.value,
      defaultLightSettings: defaultLightSettings.value,
      vibrateTimings: absentIfEmptyList(vibrateTimings.value),
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

/// `isRequired: false` on every one — `GladeStringInput` defaults to required,
/// and missing this on a single input would leave the whole form invalid until
/// that field was filled.
GladeStringInput _text(String name) =>
    GladeStringInput(inputKey: 'android.notification.$name', isRequired: false);

/// One of FCM's optional flags, which needs three states rather than two.
///
/// `GladeBoolInput` is a `GladeInput<bool>` and cannot hold null, so it could not
/// tell "the user chose false" from "the user chose nothing".
GladeInput<bool?> _flag(String name) => GladeInput<bool?>.optional(
  inputKey: 'android.notification.$name',
  value: null,
);

GladeInput<E?> _choice<E extends Enum>(String name) => GladeInput<E?>.optional(
  inputKey: 'android.notification.$name',
  value: null,
);

/// Typed over the whole collection so the row editor can hand back a list and
/// `updateValue` takes it like any other value. Holding these outside `inputs`
/// would put them outside glade's validity and dirty tracking.
GladeInput<List<String>?> _stringList(String name) =>
    GladeInput<List<String>?>.optional(
      inputKey: 'android.notification.$name',
      value: null,
    );
