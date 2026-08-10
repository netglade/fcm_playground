import 'wire_named.dart';

/// The delivery priority requested for a message.
///
/// Maps onto `AndroidConfig.priority` on the sending side. The two values are
/// FCM's own vocabulary rather than an abstraction over it, so there is nothing
/// to translate when reading the Firebase docs.
enum NotificationPriority implements WireNamed {
  high('high'),
  normal('normal');

  const NotificationPriority(this.wireName);

  /// The value that goes on the wire.
  ///
  /// Kept separate from the Dart identifier so renaming an enum value cannot
  /// silently change the payload a deployed sender produces.
  @override
  final String wireName;

  /// The priority named by [wireName], or `null` when nothing matches.
  ///
  /// Returns `null` instead of throwing because a payload from an older or
  /// newer sender must not be able to break the receiver.
  static NotificationPriority? fromWireName(String wireName) =>
      wireNamedFrom(values, wireName);
}
