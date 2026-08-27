import 'package:fcm_app/domains/runs/run_scheduler.dart';
import 'package:fcm_app/domains/runs/run_scheduler_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [RunScheduler] used when Firebase failed to start: every call fails with the
/// reason, so the app never special-cases a null scheduler.
class UnavailableRunScheduler implements RunScheduler {
  const UnavailableRunScheduler(this.reason);

  final String reason;

  @override
  Future<ScheduledRun> schedule(ScheduleRunRequest _) => _failure();

  @override
  Future<List<RunSummary>> list() => _failure();

  @override
  Future<ScheduledRun> fetch(String _) => _failure();

  @override
  Future<int> cancel(String _) => _failure();

  Future<T> _failure<T>() => Future.error(RunSchedulerException(reason));
}
