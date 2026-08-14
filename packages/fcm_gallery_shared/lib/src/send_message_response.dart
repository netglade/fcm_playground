import 'json_field.dart';

/// The response to a successful `POST /send` request to the local FCM API.
///
/// The server assigns the [messageId], the [traceId] and records the [sentAt]
/// time; the caller never provides these, so they are always server-generated
/// and thus trustworthy for coordination with FCM's logs and the inbox arrival
/// time.
class SendMessageResponse {
  /// Creates a response after sending a message.
  const SendMessageResponse({
    required this.messageId,
    required this.sentAt,
    required this.traceId,
  });

  /// Parses a response body, reading the message id from FCM and normalising
  /// the timestamp to UTC.
  factory SendMessageResponse.fromJson(Map<String, Object?> json) =>
      SendMessageResponse(
        messageId: requireText(json['messageId'], 'messageId'),
        sentAt: requireTimestamp(json['sentAt'], 'sentAt'),
        traceId: requireText(json['traceId'], 'traceId'),
      );

  /// FCM's own message name, e.g. `projects/p/messages/0:17…`. Useful only for
  /// correlating with FCM's logs.
  final String messageId;

  /// When the server sent the message, in UTC.
  final DateTime sentAt;

  /// The id this send is traced by, minted by the server and also injected into
  /// the message's `data` as `trace_id`.
  ///
  /// The handle that ties a send to what the receiving devices then report about
  /// it, so it is the value to quote when asking what became of one push. Spelt
  /// camelCase here because this envelope is camelCase throughout; the `data`
  /// key it travels under to the handset is `trace_id`, matching the snake_case
  /// wire format the telemetry events use.
  final String traceId;

  /// Serialises the response.
  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'sentAt': sentAt.toIso8601String(),
    'traceId': traceId,
  };
}
