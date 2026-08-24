import 'pending_reply.dart';

/// Where typed replies live between the isolate that receives one and the app.
///
/// Two collections, for the reason `PushPayloadStore` gives: two isolates write
/// here. The notification-response isolate only ever appends to the pending
/// list; the UI isolate drains it and owns the merged map. Neither
/// read-modify-writes the other's collection, so a reply arriving mid-write
/// cannot be lost.
abstract interface class ReplyStore {
  /// Appends one reply. Called **only** from the notification-response isolate.
  Future<void> appendPending(PendingReply reply);

  /// Returns the pending replies and clears them, so none is merged twice.
  Future<List<PendingReply>> takePending();

  Future<Map<String, String>> load();

  /// Replaces the merged replies. The caller has already pruned.
  Future<void> save(Map<String, String> replies);
}
