import 'wire_named.dart';

/// The kind of notification a sandbox message stands for.
///
/// Travels in the FCM data payload under the `event` key. Nothing in `core` has
/// to know about it: `PushMessageParser` passes keys it does not recognise
/// straight through to `PushMessage.data`.
enum NotificationEvent implements WireNamed {
  chatMessage('chat_message'),
  buildFinished('build_finished'),
  promo('promo'),
  silentSync('silent_sync');

  const NotificationEvent(this.wireName);

  /// The value that goes on the wire.
  ///
  /// Kept separate from the Dart identifier so renaming an enum value cannot
  /// silently change the payload a deployed sender produces.
  @override
  final String wireName;

  /// The event named by [wireName], or `null` when nothing matches.
  ///
  /// Returns `null` instead of throwing because a payload from an older or
  /// newer sender must not be able to break the inbox.
  static NotificationEvent? fromWireName(String wireName) =>
      wireNamedFrom(values, wireName);
}
