import 'package:fcm_app/pages/sandbox/forms/absent_if_empty.dart';
import 'package:fcm_app/pages/sandbox/forms/apns_fcm_options_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits `apns` — how FCM hands a message to Apple's push notification service,
/// and what it hands over.
///
/// Mirrors [ApnsConfig] field for field. FCM requires nothing here, so every
/// input is optional and [toModel] returns null while the whole block is
/// untouched.
class ApnsConfigForm extends GladeModel {
  /// The HTTP headers FCM sends on to APNs. Apple, not FCM, decides which are
  /// valid, so nothing validates them here.
  late GladeInput<Map<String, String>?> headers;

  /// Apple's own payload, forwarded verbatim.
  ///
  /// Held as one nested map rather than as typed fields, so an `aps` key Apple
  /// ships tomorrow is writable today. The dotted-path row editor is only a view
  /// over it, so [toModel] reads the value directly.
  late GladeInput<Map<String, Object?>?> payload;

  /// The APNs flavour, which carries an `image` the generic block does not.
  late ApnsFcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [headers, payload];

  /// This form and every model beneath it — see `FcmMessageForm.allModels`.
  List<GladeModelBase> get allModels => [this, ...fcmOptions.allModels];

  /// Whether every input here and in the nested options block is valid — see
  /// `AndroidNotificationForm.isValid` for why this composes per level.
  @override
  bool get isValid => super.isValid && fcmOptions.isValid;

  @override
  void initialize() {
    headers = GladeInput<Map<String, String>?>.optional(
      inputKey: 'apns.headers',
      value: null,
    );
    payload = GladeInput<Map<String, Object?>?>.optional(
      inputKey: 'apns.payload',
      value: null,
    );
    fcmOptions = ApnsFcmOptionsForm();
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(ApnsConfig? source) {
    headers.updateValue(source?.headers);
    payload.updateValue(source?.payload);
    fcmOptions.readFrom(source?.fcmOptions);
  }

  /// The block as FCM's own model, or null when nothing is set — see
  /// `AndroidNotificationForm.toModel` for how "nothing" is decided.
  ApnsConfig? toModel() {
    final result = ApnsConfig(
      headers: absentIfEmptyText(headers.value),
      payload: absentIfEmptyObject(payload.value),
      fcmOptions: fcmOptions.toModel(),
    );

    return result == const ApnsConfig() ? null : result;
  }
}
