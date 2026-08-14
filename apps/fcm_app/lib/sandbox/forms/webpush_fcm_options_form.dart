import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fcm_notification_form.dart';

/// Edits the WebPush-specific `fcm_options` block.
///
/// Mirrors [WebpushFcmOptions]. Separate from [FcmOptions] because WebPush
/// accepts a `link` the generic block does not.
class WebpushFcmOptionsForm extends GladeModel {
  /// The page a click on the web notification opens.
  late GladeStringInput link;

  /// Groups this message with others in Firebase's analytics reporting.
  late GladeStringInput analyticsLabel;

  @override
  List<GladeInput<Object?>> get inputs => [link, analyticsLabel];

  /// This form alone — it owns no subform.
  ///
  /// A leaf of the traversal `FcmMessageForm.allModels` composes, which exists
  /// because a nested model's notification never reaches its parent, so whoever
  /// renders the tree has to listen to every model in it.
  List<GladeModelBase> get allModels => [this];

  @override
  void initialize() {
    link = GladeStringInput(
      inputKey: 'webpush.fcm_options.link',
      isRequired: false,
    );
    analyticsLabel = GladeStringInput(
      inputKey: 'webpush.fcm_options.analytics_label',
      isRequired: false,
    );
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(WebpushFcmOptions? source) {
    link.updateValue(source?.link ?? '');
    analyticsLabel.updateValue(source?.analyticsLabel ?? '');
  }

  /// The block as FCM's own model, or null when nothing is set.
  WebpushFcmOptions? toModel() {
    final result = WebpushFcmOptions(
      link: emptyMeansAbsent(link.value),
      analyticsLabel: emptyMeansAbsent(analyticsLabel.value),
    );

    return result == const WebpushFcmOptions() ? null : result;
  }
}
