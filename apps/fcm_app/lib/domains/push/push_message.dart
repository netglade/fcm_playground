/// A push notification that has been received and validated.
///
/// Instances are only created by `PushMessageParser`, so a `PushMessage` that
/// exists is always well-formed. No field is null, but `title` and `body` may be
/// empty.
class PushMessage {
  const PushMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    this.data = const {},
    this.tag,
  });

  /// Used to drop duplicate deliveries, which FCM does not guarantee against.
  final String id;

  /// Empty for a data-only push, so a caller rendering this must handle a blank
  /// string. The same goes for [body].
  final String title;

  final String body;

  /// When the sender created the message, in UTC.
  final DateTime sentAt;

  /// Payload keys beyond the reserved ones, passed through untouched.
  final Map<String, String> data;

  /// The `android.notification.tag` the sender set, if any.
  ///
  /// FCM honours this itself when it draws the tray entry: a second message with
  /// the same tag replaces the first. The app reads it so its own drawing agrees
  /// rather than stacking — see `notificationIdOf`.
  final String? tag;

  @override
  bool operator ==(Object other) {
    if (other is! PushMessage) {
      return false;
    }

    return id == other.id &&
        title == other.title &&
        body == other.body &&
        sentAt == other.sentAt &&
        tag == other.tag &&
        _mapEquals(data, other.data);
  }

  @override
  int get hashCode => Object.hash(id, title, body, sentAt, tag, data.length);

  @override
  String toString() => 'PushMessage(id: $id, title: $title, sentAt: $sentAt)';
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) {
    return false;
  }

  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}
