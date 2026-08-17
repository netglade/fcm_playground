import 'package:collection/collection.dart';

import 'apns_fcm_options.dart';
import 'json_object_reader.dart';

/// FCM's `ApnsConfig`, nested under `Message.apns`: headers for Apple's push
/// service, plus Apple's own `aps` dictionary carried verbatim.
class ApnsConfig {
  /// Creates an APNs configuration, leaving unset fields for FCM and the
  /// client app to fall back on.
  const ApnsConfig({this.headers, this.payload, this.fcmOptions});

  factory ApnsConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'apns'));

  static ApnsConfig read(JsonObjectReader reader) {
    final config = ApnsConfig(
      headers: reader.stringMap('headers'),
      payload: reader.freeForm('payload'),
      fcmOptions: reader.object('fcm_options', ApnsFcmOptions.read),
    );
    reader.requireNothingUnclaimed();

    return config;
  }

  /// Such as `apns-priority` and `apns-push-type`. FCM does not validate these.
  final Map<String, String>? headers;

  /// Sent to APNs unchanged. Deliberately untyped, so an `aps` key Apple ships
  /// tomorrow is writable today.
  final Map<String, Object?>? payload;

  final ApnsFcmOptions? fcmOptions;

  Map<String, Object?> toJson() => {
    'headers': ?headers,
    'payload': ?payload,
    'fcm_options': ?fcmOptions?.toJson(),
  };

  static const _stringMap = MapEquality<String, String>();
  static const _freeFormMap = MapEquality<String, Object?>();

  @override
  bool operator ==(Object other) =>
      other is ApnsConfig &&
      _stringMap.equals(headers, other.headers) &&
      _freeFormMap.equals(payload, other.payload) &&
      fcmOptions == other.fcmOptions;

  @override
  int get hashCode => Object.hashAll([
    ...?headers?.entries.map((e) => MapEntry(e.key, e.value)),
    ...?payload?.entries.map((e) => MapEntry(e.key, e.value)),
    fcmOptions,
  ]);
}
