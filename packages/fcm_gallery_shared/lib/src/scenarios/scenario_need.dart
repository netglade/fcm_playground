/// What a scenario needs, beyond a payload, before it demonstrates anything.
///
/// Most values are a planned sub-project, so "which scenarios does the styles work
/// unblock?" is a filter rather than a search through prose. Two values are
/// exceptions, for different reasons: [externalApproval] is permanently outside
/// this project's control, while [nativeCode] names something this project has
/// decided never to build.
///
/// A value no scenario names any more has finished its sub-project and is retired
/// from here rather than left to sit unused — `interaction`, `channels` and
/// `styles` all left this way. `scenario_gallery_test.dart` enforces that: an
/// unused value fails the suite until someone removes it.
enum ScenarioNeed {
  /// The launcher icon's badge count.
  badge,

  /// A registry of every registered token, so a message can fan out.
  targeting,

  /// A step on the device or over adb that no payload can perform.
  manualStep,

  /// Approval or capability from Apple or the OS that this project cannot grant
  /// itself: a critical-alert entitlement, a Notification Service Extension,
  /// notification-policy access.
  externalApproval,

  /// A platform-level component this Dart-only gallery deliberately does not
  /// carry.
  ///
  /// Unlike the others, this value names no planned sub-project. It marks a
  /// scenario whose demonstration would need native code, which this project has
  /// chosen not to introduce — the single Kotlin file here is Flutter's own empty
  /// activity.
  nativeCode,
}
