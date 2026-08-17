import 'package:collection/collection.dart';

import 'json_object_reader.dart';
import 'webpush_fcm_options.dart';

/// FCM's `WebpushConfig`, nested under `Message.webpush`: gateway headers, a data
/// payload only WebPush receives, and the Web Notification API's own options.
class WebpushConfig {
  /// Creates a WebPush configuration, leaving unset fields for FCM and the
  /// client app to fall back on.
  const WebpushConfig({
    this.headers,
    this.data,
    this.notification,
    this.fcmOptions,
  });

  factory WebpushConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'webpush'));

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

  /// Recognised by the gateway, such as `TTL`. FCM does not validate these.
  final Map<String, String>? headers;

  /// WebPush-specific; Android receives data via `AndroidConfig.data`.
  final Map<String, String>? data;

  /// Sent to the browser unchanged. Deliberately untyped, so an option a browser
  /// vendor ships tomorrow is writable today.
  final Map<String, Object?>? notification;

  final WebpushFcmOptions? fcmOptions;

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
