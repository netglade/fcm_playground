import 'notification_draft.dart';

/// What the app asks the `sendNotification` callable to do.
///
/// The token is the caller's own registration token: the sandbox only ever
/// sends to the device it is running on, which is why an unauthenticated
/// function is an acceptable risk here.
class SendNotificationRequest {
  const SendNotificationRequest({required this.token, required this.draft});

  /// Reads a request written by [toJson].
  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    if (token == null) {
      throw const FormatException('sendNotification request has no token');
    }

    final draft = json['draft'];
    if (draft is! Map<String, dynamic>) {
      throw const FormatException('sendNotification request has no draft');
    }

    return SendNotificationRequest(
      token: token,
      draft: NotificationDraft.fromJson(draft),
    );
  }

  /// The FCM registration token of the device that should receive the message.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  Map<String, dynamic> toJson() => {'token': token, 'draft': draft.toJson()};

  @override
  bool operator ==(Object other) =>
      other is SendNotificationRequest &&
      token == other.token &&
      draft == other.draft;

  @override
  int get hashCode => Object.hash(token, draft);

  @override
  String toString() => 'SendNotificationRequest(draft: $draft)';
}
