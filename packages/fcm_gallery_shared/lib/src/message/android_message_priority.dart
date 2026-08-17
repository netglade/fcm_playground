/// How eagerly FCM delivers the message. `HIGH` wakes a dozing device immediately;
/// `NORMAL` may be held until the next maintenance window, which is the usual
/// reason a test push seems not to arrive.
enum AndroidMessagePriority {
  normal('NORMAL'),
  high('HIGH');

  const AndroidMessagePriority(this.wireName);

  final String wireName;
}
