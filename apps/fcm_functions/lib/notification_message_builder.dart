import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';

/// Turns a [NotificationDraft] into the message the Admin SDK sends.
///
/// Pure translation, with no Firebase runtime and no network, so it can be
/// exercised exhaustively with plain `dart test`. Everything that needs a live
/// project sits behind `FcmMessageSender` instead.
class NotificationMessageBuilder {
  const NotificationMessageBuilder();

  /// The message for [draft], addressed to [token].
  ///
  /// [payloadId] and [sentAt] are supplied rather than generated here so the
  /// handler can report the same values it sent.
  TokenMessage build({
    required NotificationDraft draft,
    required String token,
    required String payloadId,
    required DateTime sentAt,
  }) {
    final delivery = draft.delivery;

    return TokenMessage(
      token: token,
      data: _data(draft: draft, payloadId: payloadId, sentAt: sentAt),
      notification: delivery.asNotification
          ? Notification(title: draft.title, body: draft.body)
          : null,
      android: AndroidConfig(priority: _androidPriority(delivery.priority)),
      apns: delivery.asNotification ? null : _silentApnsConfig(),
    );
  }

  /// The flat data payload, shaped so `PushMessageParser` accepts it.
  ///
  /// The caller's extra keys are spread first so the keys this builder owns
  /// always win. `NotificationDraftValidator` rejects such a collision before
  /// it gets here; this ordering means a bug there cannot produce a payload the
  /// device fails to parse.
  Map<String, String> _data({
    required NotificationDraft draft,
    required String payloadId,
    required DateTime sentAt,
  }) => {
    ...draft.data,
    'id': payloadId,
    'title': draft.title,
    'body': draft.body,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'event': draft.event.wireName,
  };

  /// Without `content-available`, iOS treats a notification-less push as
  /// nothing to do and may never hand it to the app.
  ApnsConfig _silentApnsConfig() =>
      ApnsConfig(payload: ApnsPayload(aps: Aps(contentAvailable: true)));

  AndroidConfigPriority _androidPriority(NotificationPriority priority) =>
      switch (priority) {
        NotificationPriority.high => AndroidConfigPriority.high,
        NotificationPriority.normal => AndroidConfigPriority.normal,
      };
}
