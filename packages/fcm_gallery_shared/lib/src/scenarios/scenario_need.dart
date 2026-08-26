/// What a scenario needs, beyond a payload, before it demonstrates anything.
///
/// Every value is a planned sub-project, so "which scenarios does the styles work
/// unblock?" is a filter rather than a search through prose. [externalApproval] is
/// the one exception — it is permanently outside this project's control. A value
/// with no scenario left naming it has finished its sub-project and is retired
/// from here, not left to sit unused — `channels` was the first.
enum ScenarioNeed {
  /// Local notification styles: big picture, big text, inbox, messaging,
  /// progress, large icon.
  styles,

  /// Action buttons, inline reply, delete intents, deep-link routing and the
  /// full-screen intent.
  interaction,

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
}
