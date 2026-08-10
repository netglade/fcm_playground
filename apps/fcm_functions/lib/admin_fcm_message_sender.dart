import 'package:firebase_admin_sdk/messaging.dart';

import 'fcm_message_sender.dart';

/// The production [FcmMessageSender], backed by the Firebase Admin SDK.
///
/// Thin on purpose — it holds no logic worth testing, which is the point of the
/// interface it implements.
class AdminFcmMessageSender implements FcmMessageSender {
  const AdminFcmMessageSender(this._messaging);

  final Messaging _messaging;

  @override
  Future<String> send(TokenMessage message) => _messaging.send(message);
}
