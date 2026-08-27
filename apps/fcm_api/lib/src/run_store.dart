import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// One item taken off the queue, with the run it belongs to.
///
/// A record, not a class: it lives only between [RunStore.claimDue] and the
/// dispatch after it.
typedef ClaimedItem = (String runId, ScheduledRunItem item);

/// Where scheduled runs are kept.
///
/// Two implementations for the same reason [TelemetryStore] has two: SQLite in
/// production, and a possibly-absent native library must not decide whether the
/// suite can run. [InMemoryRunStore] pins every behaviour here, which makes it
/// the definition rather than a convenience.
abstract interface class RunStore {
  /// Stores a newly created run. Overwrites one with the same id, which only a
  /// colliding id generator could produce.
  Future<void> save(ScheduledRun run);

  Future<ScheduledRun?> find(String id);

  /// The newest [limit] runs, newest first. `createdAt` ties break by descending
  /// id, so two runs made in one instant still have a fixed order.
  Future<List<ScheduledRun>> recent({int limit = 50});

  /// Every run still holding a `pending` or `dispatching` item, for the sweep at
  /// startup. Order is unspecified: the sweep visits all of them.
  Future<List<ScheduledRun>> unfinished();

  /// Moves every `pending` item due at or before [now] to `dispatching` and
  /// returns them.
  ///
  /// In due order, ties broken by run id then item index. The caller dispatches
  /// sequentially, so this is the order pushes reach FCM and the order their
  /// timestamps land in — the thing this project measures.
  ///
  /// **One call on purpose.** Reading then writing would leave an `await` between
  /// them, and a `DELETE /runs/{id}` in that gap could cancel an item already on
  /// its way to FCM. Implementations must not suspend: trivial in memory, one
  /// transaction in SQLite.
  Future<List<ClaimedItem>> claimDue(DateTime now);

  /// Moves every still-`pending` item of [runId] to `cancelled` and reports how
  /// many, or null when there is no such run.
  ///
  /// Zero is a success — pressing Cancel a moment too late is not an error.
  Future<int?> cancelPending(String runId);

  /// Replaces the item at `item.index` in [runId]. Does nothing if the run is gone.
  Future<void> updateItem(String runId, ScheduledRunItem item);

  Future<void> close();
}
