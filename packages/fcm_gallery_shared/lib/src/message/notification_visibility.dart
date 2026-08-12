/// Whether the notification content shows on a locked screen.
///
/// Android's `NotificationCompat.Visibility`. Controls how much of the
/// notification is visible to the user when the device is locked.
enum NotificationVisibility {
  unspecified('VISIBILITY_UNSPECIFIED'),
  private('PRIVATE'),
  public('PUBLIC'),
  secret('SECRET');

  const NotificationVisibility(this.wireName);

  /// The spelling FCM uses on the wire.
  final String wireName;
}
