import 'json_field.dart';

/// The response to a successful `POST /send` request to the local FCM API.
///
/// The server assigns the [messageId] and records the [sentAt] time; the caller
/// never provides these, so they are always server-generated and thus trustworthy
/// for coordination with FCM's logs and the inbox arrival time.
class SendMessageResponse {
  /// Creates a response after sending a message.
  const SendMessageResponse({required this.messageId, required this.sentAt});

  /// Parses a response body, reading the message id from FCM and normalising
  /// the timestamp to UTC.
  factory SendMessageResponse.fromJson(Map<String, Object?> json) =>
      SendMessageResponse(
        messageId: requireText(json['messageId'], 'messageId'),
        sentAt: requireTimestamp(json['sentAt'], 'sentAt'),
      );

  /// FCM's own message name, e.g. `projects/p/messages/0:17…`. Useful only for
  /// correlating with FCM's logs.
  final String messageId;

  /// When the server sent the message, in UTC.
  final DateTime sentAt;

  /// Serialises the response.
  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'sentAt': sentAt.toIso8601String(),
  };
}
