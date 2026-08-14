/// How eagerly FCM should deliver the message to an Android device.
///
/// FCM's `AndroidConfig.priority`. `HIGH` wakes a dozing device immediately;
/// `NORMAL` may be held until the next maintenance window, which is the usual
/// reason a test push seems not to arrive.
enum AndroidMessagePriority {
  normal('NORMAL'),
  high('HIGH');

  const AndroidMessagePriority(this.wireName);

  /// The spelling FCM uses on the wire.
  final String wireName;
}
