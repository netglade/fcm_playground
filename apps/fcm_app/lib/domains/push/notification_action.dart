/// The `data` key a payload names its action buttons in.
///
/// This project's convention, not an FCM field — FCM cannot express a button,
/// so they ride in `data` and the client builds them.
const notificationActionsKey = 'actions';

/// Android shows a fourth action only by overflowing, which reads as a bug in a
/// gallery whose point is showing what the platform does.
const _maxActions = 3;

/// One button on a notification: the id that comes back when it is pressed, and
/// the label the user reads.
class NotificationAction {
  const NotificationAction(this.id, this.label, {this.takesInput = false});

  final String id;

  final String label;

  /// Whether pressing this opens a text field in the notification instead of
  /// opening the app.
  ///
  /// Defaulted: an action saying nothing about input is a plain button.
  final bool takesInput;

  @override
  bool operator ==(Object other) =>
      other is NotificationAction &&
      id == other.id &&
      label == other.label &&
      takesInput == other.takesInput;

  @override
  int get hashCode => Object.hash(id, label, takesInput);

  @override
  String toString() =>
      'NotificationAction($id, $label${takesInput ? ', input' : ''})';
}

/// Parses the `|`-separated `id:Label[:input]` list in [raw].
///
/// The third field marks an action as taking typed input, and counts as a flag
/// only when it trims to exactly `input` — so a label may still contain a colon.
///
/// Never throws: a missing key, malformed pair or repeated id costs that button
/// alone. A Sandbox payload must not lose its notification to one typo.
List<NotificationAction> parseNotificationActions(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }

  final actions = <NotificationAction>[];
  final seen = <String>{};
  for (final entry in raw.split('|')) {
    final separator = entry.indexOf(':');
    if (separator < 0) {
      continue;
    }

    final id = entry.substring(0, separator).trim();
    // Not `split(':')`: a label may contain a colon, and only the first one
    // separates the id from it.
    var label = entry.substring(separator + 1).trim();

    // A flag only when exactly `input`; anything else belongs to the label,
    // which keeps `open:Open: build 128` working. A label truly ending in
    // `:input` is unreachable — an escape syntax would tax every payload for a
    // case nobody has.
    final flagAt = label.lastIndexOf(':');
    final takesInput =
        flagAt >= 0 && label.substring(flagAt + 1).trim() == 'input';
    if (takesInput) {
      label = label.substring(0, flagAt).trim();
    }

    if (id.isEmpty || label.isEmpty || !seen.add(id)) {
      continue;
    }

    actions.add(NotificationAction(id, label, takesInput: takesInput));
    if (actions.length == _maxActions) {
      break;
    }
  }

  return List.unmodifiable(actions);
}

/// The label [raw] gave [id], or [id] itself when it names no such action.
///
/// The fallback is load-bearing: a press is read back later, when the payload
/// may name different buttons, or none that were kept.
String notificationActionLabel(String? raw, String id) {
  for (final action in parseNotificationActions(raw)) {
    if (action.id == id) {
      return action.label;
    }
  }

  return id;
}
