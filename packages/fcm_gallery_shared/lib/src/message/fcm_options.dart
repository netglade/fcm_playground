import 'package:fcm_gallery_shared/src/message/json_object_reader.dart';

/// Delivery options FCM applies on every platform. Separate from [ApnsFcmOptions]
/// and [WebpushFcmOptions] because those accept extra fields this block rejects.
class FcmOptions {
  const FcmOptions({this.analyticsLabel});

  factory FcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'fcm_options'));

  static FcmOptions read(JsonObjectReader reader) {
    final options = FcmOptions(analyticsLabel: reader.text('analytics_label'));
    reader.requireNothingUnclaimed();

    return options;
  }

  final String? analyticsLabel;

  Map<String, Object?> toJson() => {'analytics_label': ?analyticsLabel};

  @override
  bool operator ==(Object other) =>
      other is FcmOptions && analyticsLabel == other.analyticsLabel;

  @override
  int get hashCode => analyticsLabel.hashCode;
}
