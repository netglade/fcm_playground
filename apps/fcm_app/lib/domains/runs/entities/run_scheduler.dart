import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A way to ask the API to hold a send, and to find out what became of it.
///
/// The same seam as `NotificationSender` and `PushSource`, so no widget test
/// constructs an HTTP client.
abstract interface class RunScheduler {
  /// Schedules [request], or throws `RunSchedulerException` with a message that is
  /// safe to show to the user.
  Future<ScheduledRun> schedule(ScheduleRunRequest request);

  /// The recent runs, newest first, without their messages.
  Future<List<RunSummary>> list();

  /// One run with each item's timeline.
  Future<ScheduledRun> fetch(String runId);

  /// Cancels whatever of [runId] has not gone out, and reports how many. Zero is a
  /// success: the batch had simply already finished.
  Future<int> cancel(String runId);
}
