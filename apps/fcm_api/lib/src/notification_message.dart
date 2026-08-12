import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// The FCM HTTP v1 request body for one draft.
///
/// Pure translation, so the exact payload FCM will receive is assertable in a
/// unit test without a network or a credential.
class NotificationMessage {
  const NotificationMessage({
    required this.token,
    required this.draft,
    required this.payloadId,
    required this.sentAt,
  });

  /// The registration token to deliver to.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  /// The `id` data key. Stamped by the server, and echoed to the caller so the
  /// send can be matched to the arrival in the inbox.
  final String payloadId;

  /// The `sentAt` data key, in UTC.
  final DateTime sentAt;

  /// The body to POST to `…/messages:send`.
  ///
  /// `title` and `body` appear twice on purpose: the `notification` block is what
  /// the OS renders while the app is backgrounded, and the `data` copies are what
  /// `PushMessageParser` reads — it requires all four of `id`, `title`, `body`
  /// and `sentAt` to be present in `data`.
  ///
  /// The extra keys are spread last, but they cannot shadow the required four:
  /// the validator rejects a draft whose data collides with a reserved key, and
  /// the server validates before building this.
  Map<String, Object?> toJson() => {
    'message': {
      'token': token,
      'notification': {'title': draft.title, 'body': draft.body},
      'android': {'priority': 'high'},
      'data': {
        'id': payloadId,
        'title': draft.title,
        'body': draft.body,
        'sentAt': sentAt.toIso8601String(),
        ...draft.data,
      },
    },
  };
}
