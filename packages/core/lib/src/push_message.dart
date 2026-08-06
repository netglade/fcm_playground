/// A push notification that has been received and validated.
///
/// Instances are only created by `PushMessageParser`, so a `PushMessage` that
/// exists is always well-formed — callers never have to null-check its fields.
class PushMessage {
  const PushMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    this.data = const {},
  });

  /// Identifier assigned by the sender. Used to drop duplicate deliveries,
  /// which FCM does not guarantee against.
  final String id;

  /// Short headline, suitable for a notification title or list tile.
  final String title;

  /// The message text.
  final String body;

  /// When the sender created the message, in UTC.
  final DateTime sentAt;

  /// Payload keys beyond the four required ones, passed through untouched.
  final Map<String, String> data;

  @override
  bool operator ==(Object other) {
    if (other is! PushMessage) {
      return false;
    }

    return id == other.id &&
        title == other.title &&
        body == other.body &&
        sentAt == other.sentAt &&
        _mapEquals(data, other.data);
  }

  @override
  int get hashCode => Object.hash(id, title, body, sentAt, data.length);

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
