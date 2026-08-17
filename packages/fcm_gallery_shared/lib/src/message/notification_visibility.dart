/// How much of the notification a locked screen shows.
enum NotificationVisibility {
  unspecified('VISIBILITY_UNSPECIFIED'),
  private('PRIVATE'),
  public('PUBLIC'),
  secret('SECRET');

  const NotificationVisibility(this.wireName);

  final String wireName;
}
