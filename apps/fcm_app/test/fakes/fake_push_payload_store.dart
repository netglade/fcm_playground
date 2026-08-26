import 'package:fcm_app/domains/push/push_payload_store.dart';

/// A [PushPayloadStore] held in memory, so no test touches platform channels.
class FakePushPayloadStore implements PushPayloadStore {
  FakePushPayloadStore({
    List<Map<String, Object?>>? inbox,
    List<Map<String, Object?>>? pending,
    this.loadThrows = false,
  }) : inbox = inbox ?? [],
       pending = pending ?? [];

  /// The saved inbox, readable by the test to assert what was persisted.
  List<Map<String, Object?>> inbox;

  /// The queue the background isolate would have appended to.
  List<Map<String, Object?>> pending;

  /// When true, [loadInbox] fails — used to check the inbox degrades instead of
  /// stopping the app from opening.
  final bool loadThrows;

  /// How many times [saveInbox] was called, so a test can prove the inbox was
  /// persisted rather than only held in memory.
  int saves = 0;

  @override
  Future<List<Map<String, Object?>>> loadInbox() async {
    if (loadThrows) {
      throw StateError('no storage');
    }

    return List.of(inbox);
  }

  @override
  Future<void> saveInbox(List<Map<String, Object?>> payloads) async {
    inbox = List.of(payloads);
    saves++;
  }

  @override
  Future<void> appendPending(Map<String, Object?> payload) async =>
      pending.add(payload);

  @override
  Future<List<Map<String, Object?>>> takePending() async {
    final taken = List.of(pending);
    pending.clear();

    return taken;
  }
}
