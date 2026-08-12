import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A way to ask the send API for a push.
///
/// The same seam as `PushSource` on the receiving side: an interface, one
/// implementation over HTTP, and a stand-in used when the API cannot be reached
/// — so the widget tests never construct an HTTP client.
abstract interface class NotificationSender {
  /// Sends [request], or throws `NotificationSendException` with a message that
  /// is safe to show to the user.
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
