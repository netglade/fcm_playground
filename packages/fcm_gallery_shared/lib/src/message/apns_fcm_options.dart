import 'package:fcm_gallery_shared/src/message/json_object_reader.dart';

/// FCM's `ApnsFcmOptions`, separate from [FcmOptions] because APNs accepts an
/// `image` neither the generic block nor WebPush does.
class ApnsFcmOptions {
  const ApnsFcmOptions({this.image, this.analyticsLabel});

  factory ApnsFcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'apns.fcm_options'));

  static ApnsFcmOptions read(JsonObjectReader reader) {
    final options = ApnsFcmOptions(
      image: reader.text('image'),
      analyticsLabel: reader.text('analytics_label'),
    );
    reader.requireNothingUnclaimed();

    return options;
  }

  /// A URL APNs downloads, never bytes.
  final String? image;

  final String? analyticsLabel;

  Map<String, Object?> toJson() => {
    'image': ?image,
    'analytics_label': ?analyticsLabel,
  };

  @override
  bool operator ==(Object other) =>
      other is ApnsFcmOptions &&
      image == other.image &&
      analyticsLabel == other.analyticsLabel;

  @override
  int get hashCode => Object.hash(image, analyticsLabel);
}
