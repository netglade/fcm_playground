/// One reply the user typed into a notification, before the app has merged it.
///
/// Carries its own message id because it is written by an isolate that holds no
/// other state: the response callback knows the notification's payload and the
/// text, and nothing else.
class PendingReply {
  const PendingReply(this.messageId, this.text, {this.actionId = 'reply'});

  final String messageId;

  final String text;

  /// The id of the action that carried this reply, so telemetry can record which
  /// button was pressed rather than a literal that is only ever right for one of
  /// them.
  ///
  /// Defaults to `'reply'` — the catalogue's only reply action today, and also
  /// what an entry written by a build that predates this field decodes to below,
  /// so an old stored reply is read rather than dropped for a shape mismatch.
  final String actionId;

  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'text': text,
    'actionId': actionId,
  };

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

    final actionId = json['actionId'];

    return PendingReply(
      messageId,
      text,
      actionId: actionId is String && actionId.isNotEmpty ? actionId : 'reply',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PendingReply &&
      messageId == other.messageId &&
      text == other.text &&
      actionId == other.actionId;

  @override
  int get hashCode => Object.hash(messageId, text, actionId);

  @override
  String toString() => 'PendingReply($messageId, $text, actionId: $actionId)';
}
