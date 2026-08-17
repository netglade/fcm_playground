import 'package:collection/collection.dart';

import 'android_message_priority.dart';
import 'android_notification.dart';
import 'fcm_options.dart';
import 'json_object_reader.dart';

/// FCM's `AndroidConfig`, nested under `Message.android`: priority, TTL, data
/// payload and Android's own notification rendering.
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

  factory AndroidConfig.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'android'));

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

  /// Groups messages so a device that was offline receives only the last one.
  final String? collapseKey;

  /// HIGH wakes a sleeping device, NORMAL may wait for the next maintenance
  /// window.
  final AndroidMessagePriority? priority;

  /// A proto duration like `"3600s"`, after which FCM discards an undelivered
  /// message. Kept as text rather than parsed: this model's contract is round-trip
  /// fidelity.
  final String? ttl;

  /// Useful when several builds of the app are installed.
  final String? restrictedPackageName;

  /// Overrides the message's own `data` for Android clients.
  final Map<String, String>? data;

  /// Android's own rendering, distinct from the message root's notification.
  final AndroidNotification? notification;

  final FcmOptions? fcmOptions;

  /// Whether to deliver before the user unlocks a freshly rebooted device, while
  /// only system apps can run. Most apps must leave this unset.
  final bool? directBootOk;

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
