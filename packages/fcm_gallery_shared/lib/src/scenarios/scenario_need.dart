/// What a scenario needs, beyond a payload, before it demonstrates anything.
///
/// Every value is a planned sub-project, so "which scenarios does the channels work
/// unblock?" is a filter rather than a search through prose. [externalApproval] is
/// the one exception — it is permanently outside this project's control.
enum ScenarioNeed {
  /// Several notification channels, their importance, and a screen that reads
  /// that importance back from the system.
  channels('notification channels'),

  /// Local notification styles: big picture, big text, inbox, messaging,
  /// progress, large icon.
  styles('notification styles'),

  /// Action buttons, inline reply, delete intents, deep-link routing and the
  /// full-screen intent.
  interaction('notification actions'),

  /// The launcher icon's badge count.
  badge('launcher badge'),

  /// A registry of every registered token, so a message can fan out.
  targeting('a device registry'),

  /// A step on the device or over adb that no payload can perform.
  manualStep('a manual step'),

  /// Approval or capability from Apple or the OS that this project cannot grant
  /// itself: a critical-alert entitlement, a Notification Service Extension,
  /// notification-policy access.
  externalApproval('external approval');

  const ScenarioNeed(this.label);

  /// Shown to the user verbatim.
  final String label;
}
