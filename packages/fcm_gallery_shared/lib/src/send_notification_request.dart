import 'json_field.dart';
import 'notification_draft.dart';

/// The body of `POST /send`.
///
/// It serialises flat rather than nesting the draft, so this class *is* the
/// endpoint's shape instead of a wrapper around it — there is no envelope to
/// keep in agreement on two sides.
class SendNotificationRequest {
  const SendNotificationRequest({required this.token, required this.draft});

  /// Parses a flat request body, extracting the token and delegating draft
  /// fields to `NotificationDraft.fromJson` for consistency with the send API
  /// schema.
  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) =>
      SendNotificationRequest(
        token: readOptionalText(json['token'], 'token'),
        draft: NotificationDraft.fromJson(json),
      );

  /// The registration token to deliver to. The app sends its own, so the loop
  /// closes on the calling device.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  /// Serialises flat so the request *is* the endpoint body — token at the top
  /// level with the draft's fields spread alongside it.
  Map<String, dynamic> toJson() => {'token': token, ...draft.toJson()};
}
