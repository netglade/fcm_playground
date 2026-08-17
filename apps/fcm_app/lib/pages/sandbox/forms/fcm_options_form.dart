import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fcm_notification_form.dart';

/// Edits the platform-independent `fcm_options` block.
///
/// Mirrors [FcmOptions], which carries an analytics label and nothing else. The
/// APNs and WebPush blocks have their own options types accepting extra fields,
/// so they get their own forms rather than reusing this one.
class FcmOptionsForm extends GladeModel {
  /// Groups this message with others in Firebase's analytics reporting.
  late GladeStringInput analyticsLabel;

  @override
  List<GladeInput<Object?>> get inputs => [analyticsLabel];

  /// This form alone — it owns no subform.
  ///
  /// A leaf of the traversal `FcmMessageForm.allModels` composes, which exists
  /// because a nested model's notification never reaches its parent, so whoever
  /// renders the tree has to listen to every model in it.
  List<GladeModelBase> get allModels => [this];

  @override
  void initialize() {
    analyticsLabel = GladeStringInput(
      inputKey: 'fcm_options.analytics_label',
      isRequired: false,
    );
    super.initialize();
  }

  /// Fills the input from [source], clearing it when null.
  void readFrom(FcmOptions? source) {
    analyticsLabel.updateValue(source?.analyticsLabel ?? '');
  }

  /// The block as FCM's own model, or null when nothing is set.
  FcmOptions? toModel() {
    final result = FcmOptions(
      analyticsLabel: emptyMeansAbsent(analyticsLabel.value),
    );

    return result == const FcmOptions() ? null : result;
  }
}
