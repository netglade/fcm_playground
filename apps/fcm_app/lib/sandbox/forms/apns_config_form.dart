import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'absent_if_empty.dart';
import 'apns_fcm_options_form.dart';

/// Edits `apns` — how FCM hands a message to Apple's push notification service,
/// and what it hands over.
///
/// Mirrors [ApnsConfig] field for field, so the mapping in both directions stays
/// mechanical and testable without pumping a widget. Almost nothing here is a
/// plain field: two of the three are whole maps FCM never inspects, and the
/// third is a nested form.
///
/// FCM requires nothing here, so every input is optional and [toModel] returns
/// null while the whole block is untouched — the payload then omits
/// `"apns": {}` rather than sending it.
class ApnsConfigForm extends GladeModel {
  /// The HTTP headers FCM sends on the request to APNs, such as
  /// `apns-priority` and `apns-push-type`. Apple, not FCM, decides which are
  /// valid, so nothing validates them here.
  late GladeInput<Map<String, String>?> headers;

  /// Apple's own payload, forwarded verbatim: the `aps` dictionary and whatever
  /// sibling keys the sender adds.
  ///
  /// Held as one nested map rather than as typed fields, so an `aps` key Apple
  /// ships tomorrow is writable today. The input holds the whole map; the
  /// dotted-path row editor is only a view over it, so [toModel] reads the value
  /// directly and never touches the row representation.
  late GladeInput<Map<String, Object?>?> payload;

  /// Delivery options FCM applies regardless of platform, scoped to this block.
  ///
  /// The APNs flavour, which carries an `image` the generic block does not.
  late ApnsFcmOptionsForm fcmOptions;

  @override
  List<GladeInput<Object?>> get inputs => [headers, payload];

  /// Whether every input here **and in the nested options block** is valid.
  ///
  /// `GladeModel.isValid` is `inputs.every(...)`, and the subform's inputs are
  /// deliberately absent from [inputs] — `initialize()` binds everything in that
  /// list to *this* model, which would tear those inputs away from the model
  /// that owns them. So a nested block escapes the inherited getter and has to
  /// be folded back in here.
  ///
  /// It is folded in at this level rather than left to the page, because
  /// `FormSection`'s badge is per section: a green badge on `apns` while a red
  /// one hides inside a closed `apns.fcm_options` is the "invalid field the user
  /// cannot see, disabling Send for a reason they cannot find" that the badge
  /// exists to prevent.
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

  /// The block as FCM's own model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"apns": {}`. "Is anything set?" is asked
  /// by comparing against the empty instance, which cannot drift out of step as
  /// fields are added — the typed classes have value equality precisely so this
  /// works.
  ApnsConfig? toModel() {
    final result = ApnsConfig(
      headers: absentIfEmptyText(headers.value),
      payload: absentIfEmptyObject(payload.value),
      fcmOptions: fcmOptions.toModel(),
    );

    return result == const ApnsConfig() ? null : result;
  }
}
