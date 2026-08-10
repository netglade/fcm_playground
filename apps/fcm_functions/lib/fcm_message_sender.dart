import 'package:firebase_admin_sdk/messaging.dart';

/// Sends an already-built FCM message.
///
/// The seam that keeps the Admin SDK, and therefore credentials and the
/// network, out of `handleSendNotification`. It mirrors `PushSource` on the app
/// side: an interface with one real implementation and a fake in the tests.
abstract interface class FcmMessageSender {
  /// Sends [message] and returns the message name FCM assigned.
  Future<String> send(TokenMessage message);
}
