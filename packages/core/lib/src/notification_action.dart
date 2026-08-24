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
  const NotificationAction(this.id, this.label);

  final String id;

  final String label;

  @override
  bool operator ==(Object other) =>
      other is NotificationAction && id == other.id && label == other.label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'NotificationAction($id, $label)';
}

/// Parses the `|`-separated `id:Label` list in [raw].
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
    final label = entry.substring(separator + 1).trim();
    if (id.isEmpty || label.isEmpty || !seen.add(id)) {
      continue;
    }

    actions.add(NotificationAction(id, label));
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
