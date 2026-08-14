import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fcm_notification_form.dart';

/// Edits the APNs-specific `fcm_options` block.
///
/// Mirrors [ApnsFcmOptions]. Separate from [FcmOptions] because APNs accepts an
/// `image` the generic block does not — one shared form would let that field
/// through on a platform that rejects it.
class ApnsFcmOptionsForm extends GladeModel {
  /// URL of an image for the APNs notification, fetched by FCM on Apple's behalf.
  late GladeStringInput image;

  /// Groups this message with others in Firebase's analytics reporting.
  late GladeStringInput analyticsLabel;

  @override
  List<GladeInput<Object?>> get inputs => [image, analyticsLabel];

  /// This form alone — it owns no subform.
  ///
  /// A leaf of the traversal `FcmMessageForm.allModels` composes, which exists
  /// because a nested model's notification never reaches its parent, so whoever
  /// renders the tree has to listen to every model in it.
  List<GladeModelBase> get allModels => [this];

  @override
  void initialize() {
    image = GladeStringInput(
      inputKey: 'apns.fcm_options.image',
      isRequired: false,
    );
    analyticsLabel = GladeStringInput(
      inputKey: 'apns.fcm_options.analytics_label',
      isRequired: false,
    );
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(ApnsFcmOptions? source) {
    image.updateValue(source?.image ?? '');
    analyticsLabel.updateValue(source?.analyticsLabel ?? '');
  }

  /// The block as FCM's own model, or null when nothing is set.
  ApnsFcmOptions? toModel() {
    final result = ApnsFcmOptions(
      image: emptyMeansAbsent(image.value),
      analyticsLabel: emptyMeansAbsent(analyticsLabel.value),
    );

    return result == const ApnsFcmOptions() ? null : result;
  }
}
