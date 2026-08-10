import 'package:fcm_functions/fcm_message_sender.dart';
import 'package:firebase_admin_sdk/messaging.dart';

/// An [FcmMessageSender] driven by the test rather than by the Admin SDK.
class FakeFcmMessageSender implements FcmMessageSender {
  /// The message passed to [send], recorded so a test can inspect it.
  TokenMessage? sentMessage;

  /// When set, [send] throws this instead of returning a message id.
  Object? failWith;

  @override
  Future<String> send(TokenMessage message) async {
    sentMessage = message;
    if (failWith case final failure?) {
      throw failure;
    }

    return 'projects/fcm-sandbox-770fa/messages/42';
  }
}
