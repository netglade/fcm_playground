import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Asks the backend to send a notification.
///
/// The seam that keeps `cloud_functions` out of the widget tree and out of the
/// tests, exactly as `PushSource` does for `firebase_messaging`.
abstract interface class NotificationSender {
  /// Sends [request], or throws if the backend refuses or cannot be reached.
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
