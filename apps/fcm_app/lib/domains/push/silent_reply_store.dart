import 'pending_reply.dart';
import 'reply_store.dart';

/// A [ReplyStore] that keeps nothing, for the tests and for the app running
/// without storage — the same seam `SilentPressedActionStore` and
/// `SilentPushTelemetry` provide for their domains.
class SilentReplyStore implements ReplyStore {
  const SilentReplyStore();

  @override
  Future<void> appendPending(PendingReply reply) => Future<void>.value();

  @override
  Future<List<PendingReply>> takePending() async => const [];

  @override
  Future<Map<String, String>> load() async => const {};

  @override
  Future<void> save(Map<String, String> replies) => Future<void>.value();
}
