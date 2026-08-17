/// Where a scenario names no delay of its own. Every scenario is schedulable — a
/// delay is a property of the send, not of the scenario — so there has to be an
/// answer for the sixty that never expected one.
const defaultDelaySeconds = 30;

/// How long to hold a run for, and how far apart to spread it.
class ScheduleChoice {
  const ScheduleChoice({required this.delaySeconds, this.spacingSeconds = 0});

  final int delaySeconds;

  final int spacingSeconds;
}
