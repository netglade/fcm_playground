import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'android_config_form.dart';
import 'apns_config_form.dart';
import 'fcm_notification_form.dart';
import 'fcm_options_form.dart';
import 'webpush_config_form.dart';

/// Edits a whole FCM v1 `message` — the root the Sandbox sends.
///
/// Mirrors [FcmMessage] field for field. FCM requires nothing of the fields this
/// form owns — the delivery target, which it does require, is the server's to set
/// — so every input is optional.
class FcmMessageForm extends GladeModel {
  late GladeInput<Map<String, String>?> data;

  late FcmNotificationForm notification;

  late AndroidConfigForm android;

  late ApnsConfigForm apns;

  late WebpushConfigForm webpush;

  late FcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [data];

  /// Every model in the tree, the root first — what a page has to listen to.
  ///
  /// The controls read `input.value` and listen to nothing, and a nested model's
  /// notification does not reach its parent: `GladeModel` is a `ChangeNotifier`
  /// per model, with no upward wiring. Composed per level rather than spelled out
  /// here, so a subform added later is remembered once.
  List<GladeModelBase> get allModels => [
    this,
    ...notification.allModels,
    ...android.allModels,
    ...apns.allModels,
    ...webpush.allModels,
    ...fcmOptions.allModels,
  ];

  /// Whether every input here and in all five nested blocks is valid.
  ///
  /// `GladeModel.isValid` is `inputs.every(...)`, and the subforms' inputs are
  /// deliberately absent from [inputs] — `initialize()` would bind them to *this*
  /// model, tearing them away from the one that owns them. So a nested block
  /// escapes the inherited getter and has to be folded back in here.
  @override
  bool get isValid =>
      super.isValid &&
      notification.isValid &&
      android.isValid &&
      apns.isValid &&
      webpush.isValid &&
      fcmOptions.isValid;

  @override
  void initialize() {
    data = GladeInput<Map<String, String>?>.optional(
      inputKey: 'data',
      value: null,
    );
    notification = FcmNotificationForm();
    android = AndroidConfigForm();
    apns = ApnsConfigForm();
    webpush = WebpushConfigForm();
    fcmOptions = FcmOptionsForm();
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null — which is how
  /// picking a scenario replaces, rather than merges with, what was there.
  void readFrom(FcmMessage? source) {
    data.updateValue(source?.data);
    notification.readFrom(source?.notification);
    android.readFrom(source?.android);
    apns.readFrom(source?.apns);
    webpush.readFrom(source?.webpush);
    fcmOptions.readFrom(source?.fcmOptions);
  }

  /// The only `toModel` in this set that cannot return null: there is no
  /// enclosing object for an untouched root to be omitted from, and Send always
  /// needs a payload.
  FcmMessage toModel() => FcmMessage(
    data: absentIfEmptyText(data.value),
    notification: notification.toModel(),
    android: android.toModel(),
    apns: apns.toModel(),
    webpush: webpush.toModel(),
    fcmOptions: fcmOptions.toModel(),
  );
}
