import 'json_object_reader.dart';

/// Delivery options FCM applies only when the message reaches a browser
/// through WebPush.
///
/// FCM's `WebpushFcmOptions`. Separate from [FcmOptions] because WebPush
/// accepts a `link` the generic block, and APNs, do not.
class WebpushFcmOptions {
  /// Creates WebPush-specific delivery options.
  const WebpushFcmOptions({this.link, this.analyticsLabel});

  /// Reads FCM's `WebpushFcmOptions` object.
  factory WebpushFcmOptions.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'webpush.fcm_options'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static WebpushFcmOptions read(JsonObjectReader reader) {
    final options = WebpushFcmOptions(
      link: reader.text('link'),
      analyticsLabel: reader.text('analytics_label'),
    );
    reader.requireNothingUnclaimed();

    return options;
  }

  /// URL the browser opens when the user clicks the notification.
  final String? link;

  /// The label FCM attaches to this message in analytics exports.
  final String? analyticsLabel;

  /// Serialises to FCM's `WebpushFcmOptions` shape, omitting unset fields.
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
