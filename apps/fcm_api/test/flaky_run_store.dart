import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Wraps another [RunStore] and fails the first call to [updateItem], then
/// delegates every call after that — including that same first one, retried.
///
/// For proving that `SendScheduler._dispatch` still gets an item written once
/// the store recovers, even when the very first write — the trace-id persist —
/// was the one that threw.
class FlakyRunStore implements RunStore {
  FlakyRunStore(this._inner);

  final RunStore _inner;
  var _updateItemCalls = 0;

  @override
  Future<void> save(ScheduledRun run) => _inner.save(run);

  @override
  Future<ScheduledRun?> find(String id) => _inner.find(id);

  @override
  Future<List<ScheduledRun>> recent({int limit = 50}) =>
      _inner.recent(limit: limit);

  @override
  Future<List<ScheduledRun>> unfinished() => _inner.unfinished();

  @override
  Future<List<ClaimedItem>> claimDue(DateTime now) => _inner.claimDue(now);

  @override
  Future<int?> cancelPending(String runId) => _inner.cancelPending(runId);

  @override
  Future<void> updateItem(String runId, ScheduledRunItem item) async {
    _updateItemCalls++;
    if (_updateItemCalls == 1) {
      throw StateError('the run store is unavailable');
    }
    await _inner.updateItem(runId, item);
  }

  @override
  Future<void> close() => _inner.close();
}
