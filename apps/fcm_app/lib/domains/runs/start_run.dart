import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'entities/active_run_store.dart';
import 'entities/run_scheduler.dart';

/// Schedules a run and records it as the one whose result is awaited.
///
/// The two always happen together — a run nobody remembered is one the app cannot
/// reopen after being killed — so they are one call rather than a pair every caller
/// has to remember to make. It also keeps both the Sandbox's cubit and the gallery's
/// page to one collaborator instead of two.
class StartRun {
  const StartRun({required this.scheduler, required this._active});

  /// Exposed because the countdown and the timeline read runs back through it, and
  /// building a second one would be a second HTTP client.
  final RunScheduler scheduler;

  final ActiveRunStore _active;

  Future<ScheduledRun> call(ScheduleRunRequest request) async {
    final run = await scheduler.schedule(request);
    await _active.setActiveRunId(run.id);

    return run;
  }
}
