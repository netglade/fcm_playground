/// The seam between the handler and FCM.
///
/// The same shape as `PushSource` in the app: an interface, one implementation
/// over the network, and a fake in the tests — so the handler's behaviour is
/// testable without a credential or a socket.
abstract interface class FcmSender {
  /// Sends an FCM HTTP v1 request body and returns the message name FCM
  /// assigned, or throws [FcmSendException] if FCM refused it.
  Future<String> send(Map<String, Object?> message);
}
