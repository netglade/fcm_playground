import 'json_object_reader.dart';

/// Delivery options FCM applies uniformly, regardless of the target platform.
///
/// FCM's `FcmOptions`. Kept separate from [ApnsFcmOptions] and
/// [WebpushFcmOptions] because those platforms accept extra fields this
/// generic block must reject.
class FcmOptions {
  /// Creates generic delivery options.
  const FcmOptions({this.analyticsLabel});

  /// Reads FCM's `FcmOptions` object.
  factory FcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'fcm_options'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static FcmOptions read(JsonObjectReader reader) {
    final options = FcmOptions(analyticsLabel: reader.text('analytics_label'));
    reader.requireNothingUnclaimed();

    return options;
  }

  /// The label FCM attaches to this message in analytics exports.
  final String? analyticsLabel;

  /// Serialises to FCM's `FcmOptions` shape, omitting an unset label.
  Map<String, Object?> toJson() => {'analytics_label': ?analyticsLabel};

  @override
  bool operator ==(Object other) =>
      other is FcmOptions && analyticsLabel == other.analyticsLabel;

  @override
  int get hashCode => analyticsLabel.hashCode;
}
