/// Where received payloads are kept so the inbox survives a restart.
///
/// Two collections rather than one, because two isolates write here: the UI
/// isolate owns the inbox, and the background message handler only ever appends
/// to the pending list. Neither reads-modifies-writes the other's collection, so
/// a push arriving mid-write cannot be lost.
///
/// Raw payload maps are stored rather than parsed messages, so there is one
/// format on disk and `PushMessageParser` stays the only thing that validates.
abstract interface class PushPayloadStore {
  /// Payloads kept from earlier sessions, in the order they were saved.
  Future<List<Map<String, Object?>>> loadInbox();

  /// Replaces the kept payloads. The caller has already applied the cap.
  Future<void> saveInbox(List<Map<String, Object?>> payloads);

  /// Appends one payload. Called **only** from the background isolate.
  Future<void> appendPending(Map<String, Object?> payload);

  /// Returns the pending payloads and clears them, so none is drained twice.
  Future<List<Map<String, Object?>>> takePending();
}
