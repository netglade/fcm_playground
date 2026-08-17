import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// One item taken off the queue, with the run it belongs to.
///
/// A record rather than a class: it exists only between [RunStore.claimDue] and the
/// dispatch that follows, and naming a type for that would be ceremony.
typedef ClaimedItem = (String runId, ScheduledRunItem item);

/// Where scheduled runs are kept.
///
/// Two implementations for the same reason [TelemetryStore] has two: the production
/// store is SQLite, and a native library that may not be installed must not decide
/// whether the test suite can run. Every behaviour here is pinned against
/// [InMemoryRunStore], which makes it the definition rather than a convenience.
abstract interface class RunStore {
  /// Stores a newly created run. Overwrites one with the same id, which only a
  /// colliding id generator could produce.
  Future<void> save(ScheduledRun run);

  Future<ScheduledRun?> find(String id);

  /// The newest [limit] runs, newest first. Ties in `createdAt` are broken by
  /// descending id, so two runs made in the same instant still come back in a
  /// fixed order rather than whichever order the implementation happens to hold
  /// them in.
  Future<List<ScheduledRun>> recent({int limit = 50});

  /// Every run still holding a `pending` or `dispatching` item, for the sweep at
  /// startup. Order is unspecified: the sweep visits all of them.
  Future<List<ScheduledRun>> unfinished();

  /// Moves every `pending` item due at or before [now] to `dispatching` and returns
  /// them.
  ///
  /// The claimed items come back in due order, ties broken by run id then item
  /// index — never save or creation order. The caller dispatches this list
  /// sequentially, so the order here is the order pushes leave for FCM and the
  /// order their telemetry timestamps land in, which is the thing this project
  /// exists to measure; an arbitrary order would make that measurement arbitrary
  /// too.
  ///
  /// **One call on purpose.** Reading the due items and then writing them back would
  /// leave an `await` between the two, and a `DELETE /runs/{id}` landing in that gap
  /// could cancel an item that is already on its way to FCM. An implementation must
  /// therefore do both without suspending — trivially true in the in-memory store,
  /// and one transaction in SQLite.
  Future<List<ClaimedItem>> claimDue(DateTime now);

  /// Moves every still-`pending` item of [runId] to `cancelled` and reports how
  /// many, or null when there is no such run.
  ///
  /// Zero is a success: someone who pressed Cancel a moment too late should not get
  /// an error for having missed by a hair.
  Future<int?> cancelPending(String runId);

  /// Replaces the item at `item.index` in [runId]. Does nothing if the run is gone.
  Future<void> updateItem(String runId, ScheduledRunItem item);

  Future<void> close();
}

/// Whether an item is still waiting for something to happen to it.
bool isOutstanding(ScheduledRunItem item) =>
    item.state == RunItemState.pending ||
    item.state == RunItemState.dispatching;
