import 'package:collection/collection.dart';

import 'json_object_reader.dart';
import 'webpush_fcm_options.dart';

/// The WebPush-specific delivery and rendering options for a message.
///
/// FCM's `WebpushConfig`, nested under `Message.webpush`. Controls headers sent
/// to the WebPush gateway, a data payload that only WebPush receives, and a
/// free-form notification object that FCM does not inspect — it is the Web
/// Notification API's options that the sender includes.
class WebpushConfig {
  /// Creates a WebPush configuration, leaving unset fields for FCM and the
  /// client app to fall back on.
  const WebpushConfig({
    this.headers,
    this.data,
    this.notification,
    this.fcmOptions,
  });

  /// Reads FCM's `WebpushConfig` object.
  factory WebpushConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'webpush'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static WebpushConfig read(JsonObjectReader reader) {
    final config = WebpushConfig(
      headers: reader.stringMap('headers'),
      data: reader.stringMap('data'),
      notification: reader.freeForm('notification'),
      fcmOptions: reader.object('fcm_options', WebpushFcmOptions.read),
    );
    reader.requireNothingUnclaimed();

    return config;
  }

  /// HTTP headers to send with the push notification request, as key–value pairs
  /// the WebPush gateway recognizes, such as `TTL` for time-to-live. FCM does
  /// not validate these.
  final Map<String, String>? headers;

  /// The free-form data payload the app receives when the notification is
  /// delivered, as key–value pairs the sender defines. Keys are never validated
  /// by FCM, only by the app. This field is WebPush-specific; Android receives
  /// data via `AndroidConfig.data`.
  final Map<String, String>? data;

  /// The free-form notification object FCM sends to the browser unchanged,
  /// including the Web Notification API's options the sender includes. FCM does
  /// not inspect this notification; its schema is not typed on purpose, so that
  /// new Notification API options added by the browser vendors are writable
  /// today with no model change.
  final Map<String, Object?>? notification;

  /// Delivery options FCM applies uniformly, regardless of the target platform.
  final WebpushFcmOptions? fcmOptions;

  /// Serialises to FCM's `WebpushConfig` shape, omitting unset fields.
  Map<String, Object?> toJson() => {
    'headers': ?headers,
    'data': ?data,
    'notification': ?notification,
    'fcm_options': ?fcmOptions?.toJson(),
  };

  static const _stringMap = MapEquality<String, String>();
  static const _freeFormMap = MapEquality<String, Object?>();

  @override
  bool operator ==(Object other) =>
      other is WebpushConfig &&
      _stringMap.equals(headers, other.headers) &&
      _stringMap.equals(data, other.data) &&
      _freeFormMap.equals(notification, other.notification) &&
      fcmOptions == other.fcmOptions;

  @override
  int get hashCode => Object.hashAll([
    ...?headers?.entries.map((e) => MapEntry(e.key, e.value)),
    ...?data?.entries.map((e) => MapEntry(e.key, e.value)),
    ...?notification?.entries.map((e) => MapEntry(e.key, e.value)),
    fcmOptions,
  ]);
}
