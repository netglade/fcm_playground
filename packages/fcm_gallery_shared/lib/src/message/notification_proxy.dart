/// Whether Android may proxy the notification.
///
/// Android's `NotificationCompat.BubbleMetadata.BubbleConversationFlags`.
/// Controls whether Android may forward the notification to other apps or
/// destinations.
enum NotificationProxy {
  unspecified('PROXY_UNSPECIFIED'),
  allow('ALLOW'),
  deny('DENY'),
  ifPriorityLowered('IF_PRIORITY_LOWERED');

  const NotificationProxy(this.wireName);

  /// The spelling FCM uses on the wire.
  final String wireName;
}
