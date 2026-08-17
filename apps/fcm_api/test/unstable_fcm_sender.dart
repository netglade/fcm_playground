import 'package:fcm_api/fcm_api.dart';

/// An [FcmSender] whose [send] throws something other than an
/// [FcmSendException] on one call, chosen by arrival order, and otherwise
/// succeeds.
///
/// [FakeFcmSender] can only produce the failures `sendMessage` already knows
/// how to turn into a `SendRejected` — this is for the kind it does not: a
/// transport fault such as a socket error or a failed token refresh, which
/// `SendScheduler._dispatch` has to survive on its own.
class UnstableFcmSender implements FcmSender {
  UnstableFcmSender({required this.failsAt, required this.error});

  /// The zero-based index, by call order, that throws.
  final int failsAt;

  /// What that one call throws.
  final Object error;

  /// Every message handed to [send], whether or not the call then threw.
  final sent = <Map<String, Object?>>[];

  @override
  Future<String> send(Map<String, Object?> message) async {
    final index = sent.length;
    sent.add(message);
    if (index == failsAt) {
      throw error;
    }

    return 'projects/p/messages/0:$index';
  }
}
