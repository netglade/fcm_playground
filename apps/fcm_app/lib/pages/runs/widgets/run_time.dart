/// Formats an instant as `HH:MM:SS UTC`, for a run tile's next-due line and a
/// run item card's due and event times.
///
/// `.toUtc()` first: every DTO this reads (`ScheduledRunItem.dueAt`,
/// `TelemetryEvent.at`) normalises to UTC in its own constructor, so today
/// every caller already hands this a UTC instant — but that is a fact about
/// the callers, not about this function, and the label says `UTC`
/// unconditionally. One caller that skipped normalisation would make the
/// label a lie without this.
String runTime(DateTime at) {
  final utc = at.toUtc();

  return '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')} UTC';
}
