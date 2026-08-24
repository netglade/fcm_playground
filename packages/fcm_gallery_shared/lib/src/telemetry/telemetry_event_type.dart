/// One thing that happened to one message, on either side of the wire.
///
/// [dismissed] is produced only for notifications the app drew itself — see
/// `LocalNotificationPresenter`.
enum TelemetryEventType {
  /// The API accepted a send request.
  queued('queued'),

  /// FCM accepted the message, and returned a name for it.
  sent('sent'),

  /// FCM refused it. The error code goes in `detail`.
  sendFailed('send_failed'),

  /// Arrived while the app was in the foreground.
  receivedFg('received_fg'),

  /// Arrived while the app was backgrounded or killed.
  ///
  /// Only ever produced for a `data` payload: a notification-only push is drawn
  /// by the system and never wakes the background handler, so its absence here
  /// is correct rather than a missed event.
  receivedBg('received_bg'),

  /// A local notification was drawn for it.
  displayed('displayed'),

  /// The user tapped it. `detail` carries the `OpenedFrom` the tap came through.
  opened('opened'),

  /// The user pressed an action button on it. `detail` carries the action id.
  ///
  /// Emitted beside [opened] rather than instead of it: every action in this
  /// build opens the app, so the open is real and the matrix would otherwise
  /// have a hole where these scenarios should be. Android only — iOS actions
  /// need a category registered at startup, which a per-message payload cannot
  /// reach.
  action('action'),

  /// The user swiped it away without tapping.
  dismissed('dismissed'),

  /// The user said it never arrived. The only event a human asserts, and the
  /// only evidence available when the interesting answer is silence.
  notReceived('not_received');

  const TelemetryEventType(this.wireName);

  /// The string both sides agree on. Pinned by test to its literal, because a
  /// rename would otherwise show up only as telemetry that stops correlating.
  final String wireName;
}
