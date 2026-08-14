/// How prominently Android displays the notification once delivered.
///
/// Distinct from `AndroidMessagePriority`, which is about *delivery* — whether
/// FCM wakes a dozing device or may hold the message until its next maintenance
/// window. This enum controls how Android shows the notification on the screen.
enum AndroidNotificationPriority {
  unspecified('PRIORITY_UNSPECIFIED'),
  min('PRIORITY_MIN'),
  low('PRIORITY_LOW'),
  defaultPriority('PRIORITY_DEFAULT'),
  high('PRIORITY_HIGH'),
  max('PRIORITY_MAX');

  const AndroidNotificationPriority(this.wireName);

  /// The spelling FCM uses on the wire.
  final String wireName;
}
