import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits FCM's cross-platform `notification` block.
///
/// Mirrors [FcmNotification] one-for-one, so the mapping in both directions is
/// mechanical and this can be tested without pumping a widget.
class FcmNotificationForm extends GladeModel {
  /// Shown as the notification's headline.
  late GladeStringInput title;

  /// The notification's text.
  late GladeStringInput body;

  /// URL of an image for FCM to fetch and display — a URL, never bytes.
  late GladeStringInput image;

  @override
  List<GladeInput<Object?>> get inputs => [title, body, image];

  /// This form alone — it owns no subform.
  ///
  /// A leaf of the traversal `FcmMessageForm.allModels` composes, which exists
  /// because a nested model's notification never reaches its parent, so whoever
  /// renders the tree has to listen to every model in it.
  List<GladeModelBase> get allModels => [this];

  @override
  void initialize() {
    // isRequired: false on every one — GladeStringInput defaults to required,
    // and FCM has no required field in this block. Missing it on a single input
    // would leave the whole form invalid until that field was filled.
    title = GladeStringInput(inputKey: 'notification.title', isRequired: false);
    body = GladeStringInput(inputKey: 'notification.body', isRequired: false);
    image = GladeStringInput(inputKey: 'notification.image', isRequired: false);
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(FcmNotification? source) {
    title.updateValue(source?.title ?? '');
    body.updateValue(source?.body ?? '');
    image.updateValue(source?.image ?? '');
  }

  /// The block as FCM's own model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"notification": {}`. "Is anything set?"
  /// is asked by comparing against the empty instance, which cannot drift out of
  /// step as fields are added — the typed classes have value equality precisely
  /// so this works.
  FcmNotification? toModel() {
    final result = FcmNotification(
      title: emptyMeansAbsent(title.value),
      body: emptyMeansAbsent(body.value),
      image: emptyMeansAbsent(image.value),
    );

    return result == const FcmNotification() ? null : result;
  }
}

/// Empty text means the field is absent, not that it is an empty string.
///
/// FCM distinguishes the two: an empty string is a value it will act on, while
/// an omitted key leaves the platform default in place.
String? emptyMeansAbsent(String value) => value.isEmpty ? null : value;
