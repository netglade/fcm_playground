import 'package:collection/collection.dart';

import 'apns_fcm_options.dart';
import 'json_object_reader.dart';

/// The APNs-specific delivery and rendering options for a message.
///
/// FCM's `ApnsConfig`, nested under `Message.apns`. Controls headers sent to
/// Apple's push notification service and carries a free-form payload that FCM
/// does not inspect — it is Apple's `aps` dictionary and any sibling keys the
/// sender includes.
class ApnsConfig {
  /// Creates an APNs configuration, leaving unset fields for FCM and the
  /// client app to fall back on.
  const ApnsConfig({this.headers, this.payload, this.fcmOptions});

  /// Reads FCM's `ApnsConfig` object.
  factory ApnsConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'apns'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static ApnsConfig read(JsonObjectReader reader) {
    final config = ApnsConfig(
      headers: reader.stringMap('headers'),
      payload: reader.freeForm('payload'),
      fcmOptions: reader.object('fcm_options', ApnsFcmOptions.read),
    );
    reader.requireNothingUnclaimed();

    return config;
  }

  /// HTTP headers to send with the push notification request to APNs, as
  /// key–value pairs APNs defines or accepts, such as `apns-priority` and
  /// `apns-push-type`. FCM does not validate these.
  final Map<String, String>? headers;

  /// The free-form payload FCM sends to APNs unchanged, including Apple's `aps`
  /// dictionary and any sibling keys the sender includes. FCM does not inspect
  /// this payload; the `aps` dictionary's schema is not typed on purpose, so
  /// that new APNs features added by Apple are writable today with no model
  /// change.
  final Map<String, Object?>? payload;

  /// Delivery options FCM applies uniformly, regardless of the target platform.
  final ApnsFcmOptions? fcmOptions;

  /// Serialises to FCM's `ApnsConfig` shape, omitting unset fields.
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
