import 'package:fcm_app/domains/push/pending_reply.dart';

/// Where typed replies live between the isolate that receives one and the app.
///
/// Two collections, for the reason `PushPayloadStore` gives: two isolates write
/// here. The notification-response isolate only ever appends to the pending
/// list; the UI isolate drains it and owns the merged map. That split gives one
/// real guarantee: the UI isolate's writes to the merged map can never clobber
/// the response isolate's appends to the pending list, because neither isolate
/// touches the other's collection.
///
/// It does **not** make `takePending` itself atomic. Its read-then-clear is two
/// separate platform calls, so an `appendPending` landing between them can be
/// lost (the UI reads, the response isolate appends, the UI clears — the
/// appended reply vanishes) or replayed (the response isolate reads a stale
/// list and writes it back after the UI already cleared it). The window is
/// narrow in practice — a reply action deliberately does not foreground the
/// app, so the press and the next drain are rarely close together — but a
/// replay is not free: the merged map write is idempotent, so the stored text
/// is unaffected, but `PushRepository._mergeReplies` also reports the `action`
/// telemetry event on every pass, so a replayed reply double-records that
/// event against the same trace id. Only the loss case costs a reply; the
/// replay case costs a telemetry figure.
///
/// `SharedPreferencesPushPayloadStore.takePending` has the identical race; a
/// future fix should close both at once rather than diverging them.
abstract interface class ReplyStore {
  /// Appends one reply. Called **only** from the notification-response isolate.
  Future<void> appendPending(PendingReply reply);

  /// Returns the pending replies and clears them, so none is merged twice. See
  /// the class doc: the read and the clear are not atomic across isolates.
  Future<List<PendingReply>> takePending();

  Future<Map<String, String>> load();

  /// Replaces the merged replies. The caller has already pruned.
  Future<void> save(Map<String, String> replies);
}
