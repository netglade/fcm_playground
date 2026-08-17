import 'dart:async';

import 'package:fcm_api/fcm_api.dart';

/// An [FcmSender] that holds each send open until the test releases it, so a
/// second tick can be run while the first is still inside FCM.
class BlockingFcmSender implements FcmSender {
  final gate = Completer<void>();
  final sent = <Map<String, Object?>>[];

  /// Thrown instead of answering, once released — for the crash-safety case.
  Object? failure;

  @override
  Future<String> send(Map<String, Object?> message) async {
    sent.add(message);
    await gate.future;
    if (failure case final failure?) {
      throw failure;
    }

    return 'projects/p/messages/0:17';
  }
}
