/// The delivery priority requested for a message.
///
/// Maps onto `AndroidConfig.priority` on the sending side. The two values are
/// FCM's own vocabulary rather than an abstraction over it, so there is nothing
/// to translate when reading the Firebase docs.
enum NotificationPriority {
  high('high'),
  normal('normal');

  const NotificationPriority(this.wireName);

  /// The value that goes on the wire. See [NotificationEvent.wireName].
  final String wireName;

  /// The priority named by [wireName], or `null` when nothing matches.
  static NotificationPriority? fromWireName(String wireName) {
    for (final priority in values) {
      if (priority.wireName == wireName) {
        return priority;
      }
    }

    return null;
  }
}
