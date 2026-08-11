import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// What a send attempt produced: the response to return, or the error to report
/// with the status it deserves.
///
/// Sealed rather than thrown, so the router decides nothing — it switches once,
/// exhaustively — and every status code is asserted in a unit test.
sealed class SendOutcome {
  const SendOutcome();
}

/// FCM accepted the message.
final class SendSucceeded extends SendOutcome {
  const SendSucceeded(this.response);

  /// The 200 body.
  final SendNotificationResponse response;
}

/// The send did not happen, or FCM refused it.
final class SendRejected extends SendOutcome {
  const SendRejected({required this.statusCode, required this.error});

  /// The HTTP status to answer with.
  final int statusCode;

  /// The body to answer with.
  final ApiError error;
}
