import 'json_object_reader.dart';

/// Delivery options FCM applies only when the message reaches an iOS device
/// through APNs.
///
/// FCM's `ApnsFcmOptions`. Separate from [FcmOptions] because APNs accepts an
/// `image` the generic block, and WebPush, do not.
class ApnsFcmOptions {
  /// Creates APNs-specific delivery options.
  const ApnsFcmOptions({this.image, this.analyticsLabel});

  /// Reads FCM's `ApnsFcmOptions` object.
  factory ApnsFcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'apns.fcm_options'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static ApnsFcmOptions read(JsonObjectReader reader) {
    final options = ApnsFcmOptions(
      image: reader.text('image'),
      analyticsLabel: reader.text('analytics_label'),
    );
    reader.requireNothingUnclaimed();

    return options;
  }

  /// URL of an image APNs downloads and attaches to the notification — a URL,
  /// never bytes.
  final String? image;

  /// The label FCM attaches to this message in analytics exports.
  final String? analyticsLabel;

  /// Serialises to FCM's `ApnsFcmOptions` shape, omitting unset fields.
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
