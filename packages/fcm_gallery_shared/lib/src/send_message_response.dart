import 'json_field.dart';

/// The response to a successful `POST /send`. Every field is server-generated, so
/// all three are trustworthy for correlating with FCM's logs and the inbox.
class SendMessageResponse {
  const SendMessageResponse({
    required this.messageId,
    required this.sentAt,
    required this.traceId,
  });

  factory SendMessageResponse.fromJson(Map<String, Object?> json) =>
      SendMessageResponse(
        messageId: requireText(json['messageId'], 'messageId'),
        sentAt: requireTimestamp(json['sentAt'], 'sentAt'),
        traceId: requireText(json['traceId'], 'traceId'),
      );

  /// FCM's own message name, e.g. `projects/p/messages/0:17…`.
  final String messageId;

  /// In UTC.
  final DateTime sentAt;

  /// The handle that ties a send to what the receiving devices report about it.
  /// camelCase here because this envelope is camelCase throughout; the `data` key it
  /// travels under to the handset is `trace_id`.
  final String traceId;

  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'sentAt': sentAt.toIso8601String(),
    'traceId': traceId,
  };
}
