import 'package:collection/collection.dart';

import 'android_config.dart';
import 'apns_config.dart';
import 'fcm_notification.dart';
import 'fcm_options.dart';
import 'json_object_reader.dart';
import 'webpush_config.dart';

/// A message ready to send through FCM's v1 `Message` model.
///
/// This mirrors FCM's `Message` minus the delivery target — `token`, `topic`
/// and `condition`, which the server assigns, not a payload template — and
/// minus the output-only `name`, which FCM returns but never accepts.
class FcmMessage {
  /// Creates a message, leaving unset fields for FCM and the client app to
  /// fall back on.
  const FcmMessage({
    this.data,
    this.notification,
    this.android,
    this.webpush,
    this.apns,
    this.fcmOptions,
  });

  /// Reads FCM's `Message` object.
  factory FcmMessage.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'message'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static FcmMessage read(JsonObjectReader reader) {
    for (final target in const ['token', 'topic', 'condition']) {
      if (reader.text(target) != null) {
        throw FormatException(
          'message.$target: the server sets the delivery target, so a payload '
          'template must not set it',
        );
      }
    }

    final message = FcmMessage(
      data: reader.stringMap('data'),
      notification: reader.object('notification', FcmNotification.read),
      android: reader.object('android', AndroidConfig.read),
      webpush: reader.object('webpush', WebpushConfig.read),
      apns: reader.object('apns', ApnsConfig.read),
      fcmOptions: reader.object('fcm_options', FcmOptions.read),
    );
    reader.requireNothingUnclaimed();

    return message;
  }

  /// The free-form data payload the app receives, as key–value pairs the
  /// sender defines. Keys are the caller's own and travel to the client app
  /// untouched; FCM never inspects them.
  final Map<String, String>? data;

  /// The cross-platform notification to render, before any platform-specific
  /// overrides from [android], [webpush] or [apns] are applied.
  final FcmNotification? notification;

  /// Android-specific delivery and rendering options.
  final AndroidConfig? android;

  /// WebPush-specific delivery and rendering options.
  final WebpushConfig? webpush;

  /// APNs-specific delivery and rendering options, for iOS and macOS.
  final ApnsConfig? apns;

  /// Delivery options FCM applies uniformly, regardless of the target platform.
  final FcmOptions? fcmOptions;

  /// Serialises to FCM's `Message` shape, omitting unset fields.
  ///
  /// Never emits a delivery target: [FcmMessage] carries none, so one cannot
  /// leak back out through a round-trip.
  Map<String, Object?> toJson() => {
    'data': ?data,
    'notification': ?notification?.toJson(),
    'android': ?android?.toJson(),
    'webpush': ?webpush?.toJson(),
    'apns': ?apns?.toJson(),
    'fcm_options': ?fcmOptions?.toJson(),
  };

  static const _stringMap = MapEquality<String, String>();

  @override
  bool operator ==(Object other) =>
      other is FcmMessage &&
      _stringMap.equals(data, other.data) &&
      notification == other.notification &&
      android == other.android &&
      webpush == other.webpush &&
      apns == other.apns &&
      fcmOptions == other.fcmOptions;

  @override
  int get hashCode => Object.hashAll([
    ...?data?.entries.map((e) => MapEntry(e.key, e.value)),
    notification,
    android,
    webpush,
    apns,
    fcmOptions,
  ]);
}
