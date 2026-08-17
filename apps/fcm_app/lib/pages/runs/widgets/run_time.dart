/// Formats a UTC instant as `HH:MM:SS UTC`, for a run tile's next-due line and a
/// run item card's due and event times.
String runTime(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}:'
    '${at.second.toString().padLeft(2, '0')} UTC';
