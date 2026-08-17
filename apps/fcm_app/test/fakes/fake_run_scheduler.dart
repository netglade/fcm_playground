import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [RunScheduler] driven by the test rather than by the API.
class FakeRunScheduler implements RunScheduler {
  FakeRunScheduler({this.failure, this.summaries = const []});

  /// Thrown by every method when set.
  final RunSchedulerException? failure;

  /// What [list] answers.
  final List<RunSummary> summaries;

  /// Every request handed to [schedule], so a widget's payload can be asserted.
  final scheduled = <ScheduleRunRequest>[];

  /// Every run id handed to [cancel].
  final cancelled = <String>[];

  /// What [fetch] answers, keyed by run id. Falls back to the run [schedule] made.
  final Map<String, ScheduledRun> runs = {};

  /// When [schedule] runs, the run is created at this instant.
  static final createdAt = DateTime.utc(2026, 8, 17, 9, 0);

  @override
  Future<ScheduledRun> schedule(ScheduleRunRequest request) async {
    _throwIfFailing();
    scheduled.add(request);
    final run = ScheduledRun(
      id: 'run-${scheduled.length}',
      createdAt: createdAt,
      items: [
        for (final (index, item) in request.items.indexed)
          ScheduledRunItem(
            index: index,
            request: item,
            dueAt: createdAt.add(
              Duration(
                seconds: request.delaySeconds + index * request.spacingSeconds,
              ),
            ),
          ),
      ],
    );
    runs[run.id] = run;

    return run;
  }

  @override
  Future<List<RunSummary>> list() async {
    _throwIfFailing();

    // A snapshot, not the live list: a real `GET /runs` answers what the server
    // held at that moment, and a caller mutating `summaries` after the fact must
    // not silently rewrite a state this fake already emitted.
    return List.unmodifiable(summaries);
  }

  @override
  Future<ScheduledRun> fetch(String runId) async {
    _throwIfFailing();
    final run = runs[runId];
    if (run == null) {
      throw RunSchedulerException('There is no run "$runId".');
    }

    return run;
  }

  @override
  Future<int> cancel(String runId) async {
    _throwIfFailing();
    cancelled.add(runId);
    final run = runs[runId];
    if (run == null) {
      return 0;
    }

    var count = 0;
    var updated = run;
    for (final item in run.items) {
      if (item.state == RunItemState.pending) {
        count++;
        updated = updated.withItem(
          item.copyWith(state: RunItemState.cancelled),
        );
      }
    }
    runs[runId] = updated;

    return count;
  }

  void _throwIfFailing() {
    if (failure case final failure?) {
      throw failure;
    }
  }
}
