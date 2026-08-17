import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// The device's queue of telemetry events that have not reached the API yet.
///
/// Recording and sending are separate steps with a database between them,
/// because the interesting moments are the ones where the network does not
/// work: an arrival recorded on a train has to survive until a flush succeeds.
///
/// **This does not deduplicate.** The API's `TelemetryStore` is idempotent on
/// `(traceId, type, deviceId)` and it is right to be — a retried flush must not
/// double-count an arrival. Here the same two rows mean something different:
/// two identical events recorded on a device are two things that happened, and
/// discarding the second would silently lose a real observation, in the one
/// place that has no other copy of it. Collapsing them is the server's job,
/// where a lost row is recoverable from the next flush; dropping them here is
/// not recoverable at all. So the buffer keeps everything and the server
/// decides what is a duplicate.
///
/// The consequence is that a stored event has no value-based identity, which is
/// what [PendingEvent] exists to supply.
abstract interface class TelemetryBuffer {
  /// Stores [event] for a later flush.
  Future<void> add(TelemetryEvent event);

  /// The oldest [limit] events, still stored afterwards.
  ///
  /// Oldest first, by the event's own timestamp, so the reporter sends them in
  /// the order they happened and a latency is computed against the right send.
  ///
  /// [limit] bounds a flush. A handset that has been offline for a week holds
  /// thousands of events, and one request carrying all of them is the request
  /// most likely to time out — which would leave the buffer exactly as full as
  /// it was. Reading does not consume: nothing is deleted until the API has
  /// acknowledged it.
  Future<List<PendingEvent>> pending({int limit = 200});

  /// Deletes exactly the rows in [events], and nothing else.
  ///
  /// `forget` rather than `clear` because a flush is not atomic with respect to
  /// recording. Events arrive *during* one — that is the normal case on a busy
  /// handset, not an edge case — and a blanket clear afterwards would delete
  /// observations that were never sent. Passing back what [pending] returned is
  /// the only way to delete the acknowledged set and no more.
  ///
  /// An empty list is a no-op rather than an error: a flush that had nothing to
  /// send still ends here.
  Future<void> forget(List<PendingEvent> events);
}

/// A stored [TelemetryEvent] together with the row identity a flush forgets it
/// by.
///
/// It exists because `forget(List<TelemetryEvent>)` cannot be made correct.
/// [TelemetryBuffer] does not deduplicate, so two rows can be byte-identical,
/// and a delete that matched on columns would then take both when only one was
/// acknowledged — the failure `forget` exists to prevent, reintroduced inside
/// it. That is not hypothetical: three identical events with `limit: 2` sends
/// two and would delete all three, losing an event that was never sent. The
/// same matching is also silently fragile, because it depends on every column
/// round-tripping byte-exactly, and a mapper that dropped a microsecond would
/// match nothing, delete nothing and grow the buffer forever while the API
/// deduplicated the evidence away.
///
/// So the [id] the database already assigns is surfaced instead of guessed at.
/// The cost is one indirection in Task 12's reporter, which maps [event] for
/// the request body and hands the same list back to
/// [TelemetryBuffer.forget] — cheaper than a delete whose correctness depends
/// on there being no duplicates in a buffer whose whole point is to keep them.
class PendingEvent {
  /// Pairs [id] with the [event] stored under it.
  const PendingEvent({required this.id, required this.event});

  /// The buffer row this event is stored in. Meaningful only to the buffer that
  /// issued it, and only until it is forgotten.
  final int id;

  /// What was recorded.
  final TelemetryEvent event;

  @override
  bool operator ==(Object other) =>
      other is PendingEvent && id == other.id && event == other.event;

  @override
  int get hashCode => Object.hash(id, event);

  @override
  String toString() => 'PendingEvent($id, $event)';
}
