import 'package:collection/collection.dart';

import 'android_message_priority.dart';
import 'android_notification.dart';
import 'fcm_options.dart';
import 'json_object_reader.dart';

/// The Android-specific delivery and rendering options for a message.
///
/// FCM's `AndroidConfig`, nested under `Message.android`. Controls priority,
/// TTL, wake-lock retention, data payload, and platform-specific rendering
/// via the nested notification.
class AndroidConfig {
  /// Creates an Android configuration, leaving unset fields for FCM and the
  /// client app to fall back on.
  const AndroidConfig({
    this.collapseKey,
    this.priority,
    this.ttl,
    this.restrictedPackageName,
    this.data,
    this.notification,
    this.fcmOptions,
    this.directBootOk,
  });

  /// Reads FCM's `AndroidConfig` object.
  factory AndroidConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'android'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static AndroidConfig read(JsonObjectReader reader) {
    final config = AndroidConfig(
      collapseKey: reader.text('collapse_key'),
      priority: reader.enumValue(
        'priority',
        AndroidMessagePriority.values,
        (value) => value.wireName,
      ),
      ttl: reader.text('ttl'),
      restrictedPackageName: reader.text('restricted_package_name'),
      data: reader.stringMap('data'),
      notification: reader.object('notification', AndroidNotification.read),
      fcmOptions: reader.object('fcm_options', FcmOptions.read),
      directBootOk: reader.flag('direct_boot_ok'),
    );
    reader.requireNothingUnclaimed();

    return config;
  }

  /// Groups messages so that only the last one is delivered to a device that
  /// was offline. When set, all messages with the same key replace earlier ones.
  final String? collapseKey;

  /// How eagerly FCM should deliver the message to the Android device: HIGH
  /// wakes a sleeping device, NORMAL may wait until the next maintenance window.
  final AndroidMessagePriority? priority;

  /// The time-to-live for the message on Google's servers, as a proto duration
  /// like `"3600s"` (one hour). After this time, if the device has not yet
  /// received it, FCM discards the message.
  ///
  /// Kept as text rather than parsed to a Duration: this model's contract is
  /// round-trip fidelity, not a particular duration representation.
  final String? ttl;

  /// Restricts delivery to apps with this package name on the Android device,
  /// useful when multiple versions of an app are installed.
  final String? restrictedPackageName;

  /// The free-form data payload the app receives, as key–value pairs the
  /// sender defines. Keys are never validated by FCM, only by the app.
  final Map<String, String>? data;

  /// The Android-specific notification rendering, nested under this block to
  /// distinguish it from generic notification fields in the message root.
  final AndroidNotification? notification;

  /// Delivery options FCM applies uniformly, regardless of the target platform.
  final FcmOptions? fcmOptions;

  /// Whether to deliver the message before the user unlocks the device after
  /// a reboot, when the device is in direct-boot mode and only system apps
  /// can run. Most apps must wait for unlock and must leave this unset.
  final bool? directBootOk;

  /// Serialises to FCM's `AndroidConfig` shape, omitting unset fields.
  Map<String, Object?> toJson() => {
    'collapse_key': ?collapseKey,
    'priority': ?priority?.wireName,
    'ttl': ?ttl,
    'restricted_package_name': ?restrictedPackageName,
    'data': ?data,
    'notification': ?notification?.toJson(),
    'fcm_options': ?fcmOptions?.toJson(),
    'direct_boot_ok': ?directBootOk,
  };

  static const _stringMap = MapEquality<String, String>();

  @override
  bool operator ==(Object other) =>
      other is AndroidConfig &&
      collapseKey == other.collapseKey &&
      priority == other.priority &&
      ttl == other.ttl &&
      restrictedPackageName == other.restrictedPackageName &&
      _stringMap.equals(data, other.data) &&
      notification == other.notification &&
      fcmOptions == other.fcmOptions &&
      directBootOk == other.directBootOk;

  @override
  int get hashCode => Object.hashAll([
    collapseKey,
    priority,
    ttl,
    restrictedPackageName,
    ...?data?.entries.map((e) => MapEntry(e.key, e.value)),
    notification,
    fcmOptions,
    directBootOk,
  ]);
}
