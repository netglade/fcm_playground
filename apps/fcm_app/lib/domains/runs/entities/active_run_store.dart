/// Which run's result the app is waiting to show.
///
/// **This is the piece that survives the app being killed**, and it is the whole of
/// the return path: the countdown tells the user to swipe the app away, so by the
/// time there is a result there is no cubit left to hold it.
abstract interface class ActiveRunStore {
  /// The awaited run, or null when nothing is outstanding.
  Future<String?> activeRunId();

  /// Replaces whatever was there. Only the newest matters — an older run is still
  /// reachable from the Runs page.
  Future<void> setActiveRunId(String runId);

  /// Safe to call when nothing is stored.
  Future<void> clear();
}
