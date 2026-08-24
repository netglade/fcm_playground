/// The `data` key a payload names its destination in.
///
/// A convention of this project rather than an FCM field: FCM has no way to say
/// which screen to open, so the destination rides in `data` and the client routes
/// on it.
const deepLinkKey = 'deep_link';

/// The shell's destinations, in the order `AppShell`'s `IndexedStack` builds them.
///
/// Public and here rather than private to `_AppShellState`, because the deep-link
/// mapping below names the same five and two copies would drift the first time a
/// destination is added.
const inboxDestination = 0;
const scenariosDestination = 1;
const sandboxDestination = 2;
const runsDestination = 3;
const telemetryDestination = 4;

/// Where a deep link points.
///
/// Two cases because the two are acted on differently: one sets the shell's index,
/// the other pushes a route over it.
sealed class DeepLinkDestination {
  const DeepLinkDestination();
}

/// One of the five drawer destinations. Nothing is pushed for these — they live in
/// an `IndexedStack`, so arriving is a change of index.
class ShellDestination extends DeepLinkDestination {
  const ShellDestination(this.index);

  final int index;

  @override
  bool operator ==(Object other) =>
      other is ShellDestination && index == other.index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'ShellDestination($index)';
}

/// One run's timeline, which is a page pushed over the shell.
class RunTimelineDestination extends DeepLinkDestination {
  const RunTimelineDestination(this.runId);

  final String runId;

  @override
  bool operator ==(Object other) =>
      other is RunTimelineDestination && runId == other.runId;

  @override
  int get hashCode => runId.hashCode;

  @override
  String toString() => 'RunTimelineDestination($runId)';
}

const _paths = {
  '/inbox': inboxDestination,
  '/scenarios': scenariosDestination,
  '/sandbox': sandboxDestination,
  '/runs': runsDestination,
  '/telemetry': telemetryDestination,
};

/// Where [link] points, or null when it names nothing this app has.
///
/// Null is the useful answer rather than a failure: the caller opens the message
/// detail page for it, which is what a tap did before deep links existed and which
/// already shows the raw link as a data row. So an unrecognised link still tells
/// the user what the notification asked for.
///
/// Never throws. The Sandbox accepts any payload a user types, and a malformed link
/// must cost the link, not the tap.
DeepLinkDestination? deepLinkDestination(String? link) {
  if (link == null) {
    return null;
  }

  // The query names no destination this app has. Dropping it rather than
  // rejecting the link keeps an otherwise valid path working, instead of failing
  // for a reason the user cannot see.
  final path = link.trim().split('?').first;
  // One trailing slash tolerated, but not on '/' itself — that would leave an
  // empty string matching nothing, which is already the answer.
  final trimmed = path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  if (_paths[trimmed] case final index?) {
    return ShellDestination(index);
  }

  const runsPrefix = '/runs/';
  if (trimmed.startsWith(runsPrefix)) {
    final runId = trimmed.substring(runsPrefix.length);
    // A blank or nested id is not a run: fetching it would show an error the user
    // never asked for, so it falls through to the detail page like any other
    // link this app does not recognise.
    if (runId.isNotEmpty && !runId.contains('/')) {
      return RunTimelineDestination(runId);
    }
  }

  return null;
}
