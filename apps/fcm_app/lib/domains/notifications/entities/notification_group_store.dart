/// Which notifications are currently drawn in each group.
///
/// Message ids rather than a count, for two reasons. Redrawing the same message
/// — which a tagged notification does routinely — cannot double-count it. And a
/// lost write costs one entry until the next draw rewrites the list, where a
/// lost increment would be wrong for as long as the group lives.
///
/// **Both writers are drawers.** `LocalNotificationPresenter.show` and
/// `drawBackgroundNotification` each read-modify-write this one key from
/// different isolates, and `SharedPreferences` offers no compare-and-set, so a
/// write landing between another's read and write is lost. `ReplyStore` and
/// `PushPayloadStore` carry the same window, but their two-collection split does
/// not apply here — there is no appender and drainer to separate, only two
/// writers of the same thing. The cost is a summary that under-counts by one
/// until the next notification in that group redraws it.
abstract interface class NotificationGroupStore {
  Future<Map<String, List<String>>> load();

  /// Replaces the stored membership. The caller has already merged.
  Future<void> save(Map<String, List<String>> groups);

  /// Forgets every group, for when the tray itself is cleared.
  Future<void> clear();
}
