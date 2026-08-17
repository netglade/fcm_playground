import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'run_store.dart';

/// A [RunStore] in a map, for tests and for a server started without a database.
///
/// Every scheduler test uses it, so the whole contract is verified in pure Dart and
/// `melos run ci` never needs a native SQLite.
class InMemoryRunStore implements RunStore {
  /// Insertion-ordered, which is creation order — [recent] reverses it.
  final Map<String, ScheduledRun> _runs = {};

  @override
  Future<void> save(ScheduledRun run) async => _runs[run.id] = run;

  @override
  Future<ScheduledRun?> find(String id) async => _runs[id];

  @override
  Future<List<ScheduledRun>> recent({int limit = 50}) async {
    final sorted = _runs.values.toList()
      ..sort((a, b) {
        final byCreatedAt = b.createdAt.compareTo(a.createdAt);

        return byCreatedAt != 0 ? byCreatedAt : b.id.compareTo(a.id);
      });

    return sorted.take(limit).toList();
  }

  @override
  Future<List<ScheduledRun>> unfinished() async => _runs.values
      .where((run) => run.items.any((item) => item.state.isOutstanding))
      .toList();

  /// Synchronous from the first line to the last: nothing between reading an item
  /// and writing it back suspends, so a cancel cannot land in the middle. That is
  /// the contract, not an accident of this implementation.
  ///
  /// The sort at the end is synchronous too, so it does not reopen that window; it
  /// exists to agree with `SqliteRunStore`'s `ORDER BY due_at, run_id, idx`, which
  /// [RunStore.claimDue] requires of both.
  @override
  Future<List<ClaimedItem>> claimDue(DateTime now) async {
    final claimed = <ClaimedItem>[];
    for (final run in _runs.values.toList()) {
      var updated = run;
      for (final item in run.items) {
        if (item.state != RunItemState.pending || item.dueAt.isAfter(now)) {
          continue;
        }
        final taken = item.copyWith(state: RunItemState.dispatching);
        updated = updated.withItem(taken);
        claimed.add((run.id, taken));
      }
      _runs[run.id] = updated;
    }

    claimed.sort((a, b) {
      final byDueAt = a.$2.dueAt.compareTo(b.$2.dueAt);
      if (byDueAt != 0) {
        return byDueAt;
      }
      final byRunId = a.$1.compareTo(b.$1);

      return byRunId != 0 ? byRunId : a.$2.index.compareTo(b.$2.index);
    });

    return claimed;
  }

  @override
  Future<int?> cancelPending(String runId) async {
    final run = _runs[runId];
    if (run == null) {
      return null;
    }

    var cancelled = 0;
    var updated = run;
    for (final item in run.items) {
      if (item.state == RunItemState.pending) {
        cancelled++;
        updated = updated.withItem(
          item.copyWith(state: RunItemState.cancelled),
        );
      }
    }
    _runs[runId] = updated;

    return cancelled;
  }

  @override
  Future<void> updateItem(String runId, ScheduledRunItem item) async {
    final run = _runs[runId];
    if (run != null) {
      _runs[runId] = run.withItem(item);
    }
  }

  @override
  Future<void> close() => Future<void>.value();
}
