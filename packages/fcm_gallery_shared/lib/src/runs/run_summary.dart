import '../json_field.dart';
import 'run_item_state.dart';
import 'scheduled_run.dart';

/// One row of `GET /runs`: enough to list a run without carrying its messages.
///
/// A list of runs does not need sixty-six payloads per row, and `GET /runs/{id}`
/// is one tap away.
class RunSummary {
  RunSummary({
    required this.runId,
    required DateTime createdAt,
    required this.itemCount,
    required this.states,
    DateTime? nextDueAt,
  }) : createdAt = createdAt.toUtc(),
       nextDueAt = nextDueAt?.toUtc();

  /// Derived here rather than on either side alone, so the app's rendering and the
  /// server's answer cannot disagree about what "3 of 6 sent" means.
  factory RunSummary.of(ScheduledRun run) {
    final states = <RunItemState, int>{};
    DateTime? nextDueAt;
    for (final item in run.items) {
      states[item.state] = (states[item.state] ?? 0) + 1;
      final outstanding =
          item.state == RunItemState.pending ||
          item.state == RunItemState.dispatching;
      if (outstanding &&
          (nextDueAt == null || item.dueAt.isBefore(nextDueAt))) {
        nextDueAt = item.dueAt;
      }
    }

    return RunSummary(
      runId: run.id,
      createdAt: run.createdAt,
      itemCount: run.items.length,
      states: states,
      nextDueAt: nextDueAt,
    );
  }

  factory RunSummary.fromJson(Map<String, Object?> json) {
    final states = requireObject(json['states'], 'states');

    return RunSummary(
      runId: requireText(json['run_id'], 'run_id'),
      createdAt: requireTimestamp(json['created_at'], 'created_at'),
      itemCount: requireInt(json['item_count'], 'item_count'),
      states: {
        for (final entry in states.entries)
          RunItemState.fromWireName(entry.key): requireInt(
            entry.value,
            'states["${entry.key}"]',
          ),
      },
      nextDueAt: json['next_due_at'] == null
          ? null
          : requireTimestamp(json['next_due_at'], 'next_due_at'),
    );
  }

  final String runId;

  final DateTime createdAt;

  final int itemCount;

  /// Only the states this run actually holds, so a reader iterates what is there
  /// rather than filtering six zeroes.
  final Map<RunItemState, int> states;

  /// The earliest due time still outstanding, or null once nothing is.
  final DateTime? nextDueAt;

  int count(RunItemState state) => states[state] ?? 0;

  Map<String, Object?> toJson() => {
    'run_id': runId,
    'created_at': createdAt.toIso8601String(),
    'item_count': itemCount,
    'states': {
      for (final entry in states.entries) entry.key.wireName: entry.value,
    },
    'next_due_at': ?nextDueAt?.toIso8601String(),
  };
}
