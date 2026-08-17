import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'webpush_fcm_options_form.dart';

/// Edits `webpush` — how FCM hands a message to a browser's push gateway, and
/// what it hands over.
///
/// Mirrors [WebpushConfig] field for field. FCM requires nothing here, so every
/// input is optional and [toModel] returns null while the whole block is
/// untouched.
class WebpushConfigForm extends GladeModel {
  /// The gateway, not FCM, decides which headers are valid, so nothing validates
  /// them here.
  late GladeInput<Map<String, String>?> headers;

  /// Overrides the message's own `data` for browser clients. Android takes its
  /// data from `android.data` instead.
  late GladeInput<Map<String, String>?> data;

  /// The Web Notification API options, forwarded verbatim.
  ///
  /// Held as one nested map rather than as typed fields, so an option a browser
  /// vendor ships tomorrow is writable today. The dotted-path row editor is only
  /// a view over it, so [toModel] reads the value directly.
  late GladeInput<Map<String, Object?>?> notification;

  /// The WebPush flavour, which carries the `link` a click opens.
  late WebpushFcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [headers, data, notification];

  /// This form and every model beneath it — see `FcmMessageForm.allModels`.
  List<GladeModelBase> get allModels => [this, ...fcmOptions.allModels];

  /// Whether every input here and in the nested options block is valid — see
  /// `AndroidNotificationForm.isValid` for why this composes per level.
  @override
  bool get isValid => super.isValid && fcmOptions.isValid;

  @override
  void initialize() {
    headers = GladeInput<Map<String, String>?>.optional(
      inputKey: 'webpush.headers',
      value: null,
    );
    data = GladeInput<Map<String, String>?>.optional(
      inputKey: 'webpush.data',
      value: null,
    );
    notification = GladeInput<Map<String, Object?>?>.optional(
      inputKey: 'webpush.notification',
      value: null,
    );
    fcmOptions = WebpushFcmOptionsForm();
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(WebpushConfig? source) {
    headers.updateValue(source?.headers);
    data.updateValue(source?.data);
    notification.updateValue(source?.notification);
    fcmOptions.readFrom(source?.fcmOptions);
  }

  /// The block as FCM's own model, or null when nothing is set — see
  /// `AndroidNotificationForm.toModel` for how "nothing" is decided.
  WebpushConfig? toModel() {
    final result = WebpushConfig(
      headers: absentIfEmptyText(headers.value),
      data: absentIfEmptyText(data.value),
      notification: absentIfEmptyObject(notification.value),
      fcmOptions: fcmOptions.toModel(),
    );

    return result == const WebpushConfig() ? null : result;
  }
}
