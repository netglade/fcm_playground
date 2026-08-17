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
/// Mirrors [FcmMessage] field for field, so the mapping in both directions stays
/// mechanical and testable without pumping a widget. Five of its six fields are
/// whole objects, each held as a nested form rather than flattened in here.
///
/// FCM requires nothing of the fields this form owns — the delivery target,
/// which it does require, is the server's to set and is deliberately absent from
/// [FcmMessage] — so every input is optional.
class FcmMessageForm extends GladeModel {
  /// The free-form data payload the client app receives, as key–value pairs the
  /// sender defines. FCM never inspects them, which is why nothing validates
  /// them here.
  late GladeInput<Map<String, String>?> data;

  /// The cross-platform notification, rendered unless a platform block
  /// overrides it.
  late FcmNotificationForm notification;

  /// Android-specific delivery and rendering options.
  late AndroidConfigForm android;

  /// APNs-specific options, for iOS and macOS.
  late ApnsConfigForm apns;

  /// WebPush-specific options, for browsers.
  late WebpushConfigForm webpush;

  /// Delivery options FCM applies regardless of platform.
  late FcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [data];

  /// Every model in the tree, the root first — what a page has to listen to.
  ///
  /// The controls are `StatelessWidget`s that read `input.value` and listen to
  /// nothing, and a nested model's notification does **not** reach its parent:
  /// `GladeModel` is a `ChangeNotifier` per model, with no upward wiring. So
  /// listening to the root alone would leave a change three levels down in the
  /// model and off the screen — which is worse than not accepting it at all.
  ///
  /// Composed per level, exactly as [isValid] is: each form owning subforms
  /// prepends itself to its children's lists, and each leaf returns just
  /// itself. Spelling the whole tree out here instead would mean a subform added
  /// anywhere later has to be remembered *twice*, and a forgotten one is
  /// invisible in tests — it shows up only as an on-screen value that will not
  /// change.
  List<GladeModelBase> get allModels => [
    this,
    ...notification.allModels,
    ...android.allModels,
    ...apns.allModels,
    ...webpush.allModels,
    ...fcmOptions.allModels,
  ];

  /// Whether every input here **and in all five nested blocks** is valid.
  ///
  /// `GladeModel.isValid` is `inputs.every(...)`, and the subforms' inputs are
  /// deliberately absent from [inputs] — `initialize()` binds everything in that
  /// list to *this* model, which would tear those inputs away from the model
  /// that owns them. So a nested block escapes the inherited getter and has to
  /// be folded back in here.
  ///
  /// This is the getter the Send button reads, so an unfolded level would let a
  /// payload FCM rejects leave the app: the failure would arrive as an opaque
  /// 400 rather than as a red badge on the section that caused it.
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

  /// Fills the inputs from [source], clearing them when it is null.
  ///
  /// Reading null is how the Sandbox empties the whole form, and how picking a
  /// scenario replaces — rather than merges with — whatever was there before.
  void readFrom(FcmMessage? source) {
    data.updateValue(source?.data);
    notification.readFrom(source?.notification);
    android.readFrom(source?.android);
    apns.readFrom(source?.apns);
    webpush.readFrom(source?.webpush);
    fcmOptions.readFrom(source?.fcmOptions);
  }

  /// The message as FCM's own model, always non-null.
  ///
  /// The only `toModel` in this set that cannot return null: there is no
  /// enclosing object for an untouched root to be omitted from, and Send always
  /// needs a payload. An empty form yields `const FcmMessage()`, whose `toJson`
  /// is `{}` — the server then adds the delivery target and FCM has a valid,
  /// if inert, request.
  FcmMessage toModel() => FcmMessage(
    data: absentIfEmptyText(data.value),
    notification: notification.toModel(),
    android: android.toModel(),
    apns: apns.toModel(),
    webpush: webpush.toModel(),
    fcmOptions: fcmOptions.toModel(),
  );
}
