/// Which app state a notification tap arrived from.
///
/// Carried in `TelemetryEvent.detail` for `TelemetryEventType.opened`, which is why it
/// lives beside the event rather than in the app: both sides read the wire name.
///
/// The three are not a preference — they are the three channels a tap can reach the app
/// through, and each takes a different code path on the device.
enum OpenedFrom {
  /// The app was on screen, so it drew the banner itself and the plugin reported the
  /// tap.
  foreground('foreground'),

  /// The app was running but not on screen, so FCM drew the tray entry and
  /// `onMessageOpenedApp` reported the tap.
  background('background'),

  /// The tap started the process, and `getInitialMessage` is what answered it.
  killed('killed');

  const OpenedFrom(this.wireName);

  /// The string that reaches the database. Pinned by test to its literal.
  final String wireName;
}
