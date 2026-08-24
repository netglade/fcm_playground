/// One reply the user typed into a notification, before the app has merged it.
///
/// Carries its own message id because it is written by an isolate that holds no
/// other state: the response callback knows the notification's payload and the
/// text, and nothing else.
class PendingReply {
  const PendingReply(this.messageId, this.text);

  final String messageId;

  final String text;

  Map<String, Object?> toJson() => {'messageId': messageId, 'text': text};

  /// Reads one stored entry, or null when it is not one this build understands.
  static PendingReply? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      return null;
    }

    final messageId = json['messageId'];
    final text = json['text'];
    if (messageId is! String || messageId.isEmpty || text is! String) {
      return null;
    }

    return PendingReply(messageId, text);
  }

  @override
  bool operator ==(Object other) =>
      other is PendingReply &&
      messageId == other.messageId &&
      text == other.text;

  @override
  int get hashCode => Object.hash(messageId, text);

  @override
  String toString() => 'PendingReply($messageId, $text)';
}
