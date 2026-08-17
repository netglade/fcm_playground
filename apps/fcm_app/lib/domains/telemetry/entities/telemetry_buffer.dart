import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// The device's queue of telemetry events that have not reached the API yet.
///
/// Recording and sending are separate steps with a database between them, because
/// the interesting moments are the ones where the network does not work.
///
/// This does not deduplicate. Two identical events recorded on a device are two
/// things that happened, and this is the only copy of them; collapsing them is
/// the server's job, where a lost row is recoverable from the next flush.
abstract interface class TelemetryBuffer {
  Future<void> add(TelemetryEvent event);

  /// The oldest [limit] events, still stored afterwards.
  ///
  /// Oldest first, by the event's own timestamp, so a latency is computed against
  /// the right send. [limit] bounds a flush: a week's backlog sent as one request
  /// is the request most likely to time out. Reading does not consume — nothing is
  /// deleted until the API has acknowledged it.
  Future<List<PendingEvent>> pending({int limit = 200});

  /// Deletes exactly the rows in [events], and nothing else.
  ///
  /// `forget` rather than `clear` because events arrive *during* a flush, and a
  /// blanket clear afterwards would delete observations that were never sent. An
  /// empty list is a no-op.
  Future<void> forget(List<PendingEvent> events);
}

/// A stored [TelemetryEvent] together with the row identity a flush forgets it
/// by.
///
/// It exists because `forget(List<TelemetryEvent>)` cannot be made correct: the
/// buffer does not deduplicate, so two rows can be byte-identical and a delete
/// matching on columns would take both when only one was acknowledged. Three
/// identical events with `limit: 2` sends two and would delete all three.
class PendingEvent {
  const PendingEvent({required this.id, required this.event});

  /// Meaningful only to the buffer that issued it, and only until it is
  /// forgotten.
  final int id;

  final TelemetryEvent event;

  @override
  bool operator ==(Object other) =>
      other is PendingEvent && id == other.id && event == other.event;

  @override
  int get hashCode => Object.hash(id, event);

  @override
  String toString() => 'PendingEvent($id, $event)';
}
