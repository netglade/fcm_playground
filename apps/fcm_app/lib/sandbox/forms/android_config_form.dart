import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'android_notification_form.dart';
import 'fcm_notification_form.dart';
import 'fcm_options_form.dart';

/// Edits `android` — how FCM delivers a message to an Android device, and how
/// that device renders it.
///
/// Mirrors [AndroidConfig] field for field, so the mapping in both directions
/// stays mechanical and testable without pumping a widget. Two of its fields are
/// whole objects, held as nested forms rather than flattened in here: the
/// notification block has 27 fields of its own, and the options block is shared
/// in shape with the message root.
///
/// FCM requires nothing here, so every input is optional and [toModel] returns
/// null while the whole block is untouched — the payload then omits
/// `"android": {}` rather than sending it.
class AndroidConfigForm extends GladeModel {
  /// Groups messages so a device that was offline receives only the last one:
  /// every message sharing a key replaces the ones before it.
  late GladeStringInput collapseKey;

  /// How eagerly FCM delivers the message: HIGH wakes a dozing device, NORMAL
  /// may wait for the next maintenance window — the usual reason a test push
  /// seems not to arrive.
  late GladeInput<AndroidMessagePriority?> priority;

  /// How long FCM keeps trying, as a proto duration such as `3600s`. After it
  /// elapses on an undelivered message, FCM discards the message.
  late GladeStringInput ttl;

  /// Restricts delivery to the app with this package name, which matters when a
  /// device has several builds of the same app installed.
  late GladeStringInput restrictedPackageName;

  /// The Android-only data payload the app receives, overriding the message's
  /// own `data` when both are present.
  late GladeInput<Map<String, String>?> data;

  /// How Android's notification tray should render the message.
  ///
  /// A nested model rather than 27 more inputs here, and its validity is folded
  /// back in by [isValid].
  late AndroidNotificationForm notification;

  /// Delivery options FCM applies regardless of platform, scoped to this block.
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

  /// This form and every model beneath it, [notification]'s own children
  /// included.
  ///
  /// Composed per level, exactly as [isValid] is: this is the level that carries
  /// `light_settings` up from two below, and composing rather than enumerating is
  /// what stops a level being forgotten. See `FcmMessageForm.allModels` for why
  /// the whole tree has to be listened to rather than just the root.
  List<GladeModelBase> get allModels => [
    this,
    ...notification.allModels,
    ...fcmOptions.allModels,
  ];

  /// Whether every input here **and in both nested blocks** is valid.
  ///
  /// `GladeModel.isValid` is `inputs.every(...)`, and the subforms' inputs are
  /// deliberately absent from [inputs] — `initialize()` binds everything in that
  /// list to *this* model, which would tear those inputs away from the model
  /// that owns them. So a nested block escapes the inherited getter and has to
  /// be folded back in here.
  ///
  /// It is folded in at this level rather than left to the page, because
  /// `FormSection`'s badge is per section: a green badge on `android` while a
  /// red one hides inside a closed `android.notification` — or inside
  /// `light_settings`, two levels down — is the "invalid field the user cannot
  /// see, disabling Send for a reason they cannot find" that the badge exists to
  /// prevent.
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

  /// The block as FCM's own model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"android": {}`. "Is anything set?" is
  /// asked by comparing against the empty instance, which cannot drift out of
  /// step as fields are added — the typed classes have value equality precisely
  /// so this works.
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

/// One of FCM's optional strings in this block, none of which it requires.
///
/// `isRequired: false` on every one — `GladeStringInput` defaults to required,
/// and missing this on a single input would leave the whole form invalid until
/// that field was filled.
GladeStringInput _text(String name) =>
    GladeStringInput(inputKey: 'android.$name', isRequired: false);
