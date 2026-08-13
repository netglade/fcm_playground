import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'webpush_fcm_options_form.dart';

/// Edits `webpush` — how FCM hands a message to a browser's push gateway, and
/// what it hands over.
///
/// Mirrors [WebpushConfig] field for field, so the mapping in both directions
/// stays mechanical and testable without pumping a widget. Every field is a map
/// FCM never inspects, or a nested form.
///
/// FCM requires nothing here, so every input is optional and [toModel] returns
/// null while the whole block is untouched — the payload then omits
/// `"webpush": {}` rather than sending it.
class WebpushConfigForm extends GladeModel {
  /// The HTTP headers FCM sends on the request to the WebPush gateway, such as
  /// `TTL`. The gateway, not FCM, decides which are valid, so nothing validates
  /// them here.
  late GladeInput<Map<String, String>?> headers;

  /// The data payload only a browser client receives, overriding the message's
  /// own `data` when both are present. Android takes its data from
  /// `android.data` instead.
  late GladeInput<Map<String, String>?> data;

  /// The Web Notification API options, forwarded to the browser verbatim.
  ///
  /// Held as one nested map rather than as typed fields, so an option a browser
  /// vendor ships tomorrow is writable today. The input holds the whole map; the
  /// dotted-path row editor is only a view over it, so [toModel] reads the value
  /// directly and never touches the row representation.
  late GladeInput<Map<String, Object?>?> notification;

  /// Delivery options FCM applies regardless of platform, scoped to this block.
  ///
  /// The WebPush flavour, which carries the `link` a click opens — a field
  /// neither the generic nor the APNs block has.
  late WebpushFcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [headers, data, notification];

  /// Whether every input here **and in the nested options block** is valid.
  ///
  /// The subform's inputs are deliberately absent from [inputs], because
  /// `initialize()` would bind them to *this* model and tear them away from the
  /// model that owns them. So they escape the inherited getter and are folded
  /// back in here, for the reason [ApnsConfigForm.isValid] spells out: the
  /// section badge is per section, so validity has to compose at every level.
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

  /// The block as FCM's own model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"webpush": {}`. "Is anything set?" is
  /// asked by comparing against the empty instance, which cannot drift out of
  /// step as fields are added.
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
