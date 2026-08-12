import 'json_field.dart';

/// The 200 body of `POST /send`.
///
/// Every field is stamped by the server, so what the caller is told and what the
/// device receives cannot drift.
class SendNotificationResponse {
  const SendNotificationResponse({
    required this.messageId,
    required this.payloadId,
    required this.sentAt,
  });

  /// Parses a response body, reading the payload's id from the wire key `id`
  /// and normalising the timestamp to UTC.
  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) =>
      SendNotificationResponse(
        messageId: requireText(json['messageId'], 'messageId'),
        payloadId: requireText(json['id'], 'id'),
        sentAt: requireTimestamp(json['sentAt'], 'sentAt'),
      );

  /// FCM's own message name, e.g. `projects/p/messages/0:17…`. Useful only for
  /// correlating with FCM's logs.
  final String messageId;

  /// The payload's `id` data key, which is what the inbox shows — so the user
  /// can match the send to the arrival.
  final String payloadId;

  /// When the server stamped the message, in UTC.
  final DateTime sentAt;

  /// Serialises the response, writing `payloadId` under the wire key `id` so
  /// it matches the payload's data field that the inbox shows.
  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'id': payloadId,
    'sentAt': sentAt.toIso8601String(),
  };
}
