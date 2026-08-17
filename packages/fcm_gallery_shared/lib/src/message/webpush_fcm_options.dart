import 'json_object_reader.dart';

/// FCM's `WebpushFcmOptions`, separate from [FcmOptions] because WebPush accepts a
/// `link` neither the generic block nor APNs does.
class WebpushFcmOptions {
  const WebpushFcmOptions({this.link, this.analyticsLabel});

  factory WebpushFcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'webpush.fcm_options'));

  static WebpushFcmOptions read(JsonObjectReader reader) {
    final options = WebpushFcmOptions(
      link: reader.text('link'),
      analyticsLabel: reader.text('analytics_label'),
    );
    reader.requireNothingUnclaimed();

    return options;
  }

  /// Opened when the user clicks the notification.
  final String? link;

  final String? analyticsLabel;

  Map<String, Object?> toJson() => {
    'link': ?link,
    'analytics_label': ?analyticsLabel,
  };

  @override
  bool operator ==(Object other) =>
      other is WebpushFcmOptions &&
      link == other.link &&
      analyticsLabel == other.analyticsLabel;

  @override
  int get hashCode => Object.hash(link, analyticsLabel);
}
