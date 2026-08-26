/// The `data` key a payload names its action buttons in.
///
/// A convention of this project rather than an FCM field: FCM has no way to
/// express an action button, so the buttons ride in `data` and the client builds
/// them.
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

  /// Whether pressing this action opens a text field in the notification rather
  /// than opening the app.
  ///
  /// Defaulted so every existing construction keeps its meaning: an action that
  /// says nothing about input is a plain button, which is what all of them were
  /// before inline reply existed.
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
/// The optional third field marks an action as taking typed input rather than
/// just being pressed: it is a flag only when the segment trailing the last
/// colon trims to exactly `input`, so a label may still contain a colon of its
/// own, as it always could.
///
/// Never throws. A missing key, a malformed pair, or a repeated id costs the
/// caller that button and nothing else: a payload typed by hand in the Sandbox
/// must not lose its notification to a typo in one field.
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

    // The trailing segment is a flag only when it is exactly `input`. Anything
    // else is part of the label, which is what keeps `open:Open: build 128`
    // working — the case P1 pinned by test. A label genuinely ending in
    // `:input` is unreachable as a result; an escape syntax would tax every
    // payload to buy a case nobody has.
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
/// The fallback is load-bearing: a press is stored against the message and read
/// back later, by which time the payload may name different buttons — or the id
/// may have come from a Sandbox payload nobody kept.
String notificationActionLabel(String? raw, String id) {
  for (final action in parseNotificationActions(raw)) {
    if (action.id == id) {
      return action.label;
    }
  }

  return id;
}
