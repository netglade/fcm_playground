/// What the countdown does to the display, behind a seam so a widget test needs no
/// plugin.
///
/// **[dim] does not turn the screen off.** An ordinary Android app cannot: only a
/// DeviceAdmin holder can, and this project cannot grant itself that. What it does
/// is take brightness to its minimum and stop keeping the screen on, so the system's
/// own timeout finishes the job — which is what the button on screen says.
abstract interface class CountdownScreen {
  /// Holds the display awake, so it cannot sleep before the user has swiped the app
  /// out of recents.
  Future<void> keepAwake();

  Future<void> dim();

  /// Undoes both, on the way out.
  Future<void> release();

  Future<void> openBatterySettings();
}
