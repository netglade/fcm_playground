import 'package:collection/collection.dart';
import 'package:fcm_gallery_shared/src/message/android_config.dart';
import 'package:fcm_gallery_shared/src/message/apns_config.dart';
import 'package:fcm_gallery_shared/src/message/fcm_notification.dart';
import 'package:fcm_gallery_shared/src/message/fcm_options.dart';
import 'package:fcm_gallery_shared/src/message/json_object_reader.dart';
import 'package:fcm_gallery_shared/src/message/webpush_config.dart';

/// FCM's v1 `Message`, minus the delivery target — `token`, `topic` and
/// `condition`, which the server assigns rather than a payload template — and minus
/// the output-only `name`.
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

  /// Travels to the client app untouched; FCM never inspects it.
  final Map<String, String>? data;

  /// Rendered unless [android], [webpush] or [apns] overrides it.
  final FcmNotification? notification;

  final AndroidConfig? android;

  final WebpushConfig? webpush;

  final ApnsConfig? apns;

  final FcmOptions? fcmOptions;

  /// Never emits a delivery target: [FcmMessage] carries none, so one cannot leak
  /// back out through a round-trip.
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
