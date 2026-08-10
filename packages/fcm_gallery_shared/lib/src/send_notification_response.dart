/// What the `sendNotification` callable reports back.
///
/// [payloadId] is the value the function put in the payload's `id` key, so the
/// sandbox can show the id that is about to appear in the inbox. That makes the
/// round trip visible instead of something the user has to infer.
class SendNotificationResponse {
  SendNotificationResponse({
    required this.messageId,
    required this.payloadId,
    required DateTime sentAt,
  }) : sentAt = sentAt.toUtc();

  /// Reads a response written by [toJson].
  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) {
    final sentAt = DateTime.tryParse('${json['sentAt']}');
    if (sentAt == null) {
      throw FormatException('Unparseable sentAt: ${json['sentAt']}');
    }

    return SendNotificationResponse(
      messageId: '${json['messageId']}',
      payloadId: '${json['payloadId']}',
      sentAt: sentAt,
    );
  }

  /// The message name FCM assigned, useful for correlating with Firebase logs.
  final String messageId;

  /// The `id` data key the function stamped. Matches `PushMessage.id`.
  final String payloadId;

  /// When the function stamped the payload, in UTC.
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'payloadId': payloadId,
    'sentAt': sentAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is SendNotificationResponse &&
      messageId == other.messageId &&
      payloadId == other.payloadId &&
      sentAt == other.sentAt;

  @override
  int get hashCode => Object.hash(messageId, payloadId, sentAt);

  @override
  String toString() =>
      'SendNotificationResponse(payloadId: $payloadId, sentAt: $sentAt)';
}
