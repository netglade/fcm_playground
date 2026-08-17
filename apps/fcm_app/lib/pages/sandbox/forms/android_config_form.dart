import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'android_notification_form.dart';
import 'fcm_notification_form.dart';
import 'fcm_options_form.dart';

/// Edits `android` — how FCM delivers a message to an Android device, and how
/// that device renders it.
///
/// Mirrors [AndroidConfig] field for field. FCM requires nothing here, so every
/// input is optional and [toModel] returns null while the whole block is
/// untouched.
class AndroidConfigForm extends GladeModel {
  /// Groups messages so a device that was offline receives only the last one.
  late GladeStringInput collapseKey;

  /// HIGH wakes a dozing device, NORMAL may wait for the next maintenance window
  /// — the usual reason a test push seems not to arrive.
  late GladeInput<AndroidMessagePriority?> priority;

  /// A proto duration such as `3600s`; FCM discards the message once it elapses.
  late GladeStringInput ttl;

  late GladeStringInput restrictedPackageName;

  /// Overrides the message's own `data` when both are present.
  late GladeInput<Map<String, String>?> data;

  late AndroidNotificationForm notification;

  late FcmOptionsForm fcmOptions;

  /// Whether to deliver before the user unlocks a freshly rebooted device, while
  /// only system apps can run. Most apps must leave this unset.
  late GladeInput<bool?> directBootOk;

  @override
  List<GladeInput<Object?>> get inputs => [
    collapseKey,
    priority,
    ttl,
    restrictedPackageName,
    data,
    directBootOk,
  ];

  /// This form and every model beneath it — see `FcmMessageForm.allModels`.
  List<GladeModelBase> get allModels => [
    this,
    ...notification.allModels,
    ...fcmOptions.allModels,
  ];

  /// Whether every input here and in both nested blocks is valid — see
  /// `AndroidNotificationForm.isValid` for why this composes per level.
  @override
  bool get isValid =>
      super.isValid && notification.isValid && fcmOptions.isValid;

  @override
  void initialize() {
    collapseKey = _text('collapse_key');
    priority = GladeInput<AndroidMessagePriority?>.optional(
      inputKey: 'android.priority',
      value: null,
    );
    ttl = GladeStringInput(
      inputKey: 'android.ttl',
      isRequired: false,
      validator: (validator) =>
          (validator..match(
                // Anchored on purpose: match() calls hasMatch, so an unanchored
                // pattern would accept 'in 3600s or so'.
                pattern: r'^\d+(\.\d+)?s$',
                // An empty field is absent, not invalid. Without this the regex
                // runs on '' and an untouched form blocks Send.
                shouldValidate: (value) => value.isNotEmpty,
                devMessage: (_) => 'must be a duration such as 3600s',
              ))
              .build(),
    );
    restrictedPackageName = _text('restricted_package_name');
    data = GladeInput<Map<String, String>?>.optional(
      inputKey: 'android.data',
      value: null,
    );
    notification = AndroidNotificationForm();
    fcmOptions = FcmOptionsForm();
    directBootOk = GladeInput<bool?>.optional(
      inputKey: 'android.direct_boot_ok',
      value: null,
    );
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(AndroidConfig? source) {
    collapseKey.updateValue(source?.collapseKey ?? '');
    priority.updateValue(source?.priority);
    ttl.updateValue(source?.ttl ?? '');
    restrictedPackageName.updateValue(source?.restrictedPackageName ?? '');
    data.updateValue(source?.data);
    notification.readFrom(source?.notification);
    fcmOptions.readFrom(source?.fcmOptions);
    directBootOk.updateValue(source?.directBootOk);
  }

  /// The block as FCM's own model, or null when nothing is set — see
  /// `AndroidNotificationForm.toModel` for how "nothing" is decided.
  AndroidConfig? toModel() {
    final result = AndroidConfig(
      collapseKey: emptyMeansAbsent(collapseKey.value),
      priority: priority.value,
      ttl: emptyMeansAbsent(ttl.value),
      restrictedPackageName: emptyMeansAbsent(restrictedPackageName.value),
      data: absentIfEmptyText(data.value),
      notification: notification.toModel(),
      fcmOptions: fcmOptions.toModel(),
      directBootOk: directBootOk.value,
    );

    return result == const AndroidConfig() ? null : result;
  }
}

/// `isRequired: false` on every one — `GladeStringInput` defaults to required.
GladeStringInput _text(String name) =>
    GladeStringInput(inputKey: 'android.$name', isRequired: false);
