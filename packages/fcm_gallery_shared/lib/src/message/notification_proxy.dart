/// Whether Android may forward the notification to other apps or destinations.
enum NotificationProxy {
  unspecified('PROXY_UNSPECIFIED'),
  allow('ALLOW'),
  deny('DENY'),
  ifPriorityLowered('IF_PRIORITY_LOWERED');

  const NotificationProxy(this.wireName);

  final String wireName;
}
