import 'package:fcm_api/fcm_api.dart';

/// An [FcmSender] driven by the test rather than by FCM.
class FakeFcmSender implements FcmSender {
  FakeFcmSender({this.messageId = 'projects/p/messages/0:17', this.failure});

  /// Returned by [send] when [failure] is null.
  final String messageId;

  /// Thrown by [send] when set — used to check the error mapping.
  final FcmSendException? failure;

  /// Every message handed to [send], so the payload can be asserted.
  final sent = <Map<String, Object?>>[];

  @override
  Future<String> send(Map<String, Object?> message) async {
    sent.add(message);
    if (failure case final failure?) {
      throw failure;
    }

    return messageId;
  }
}
