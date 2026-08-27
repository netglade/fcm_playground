/// The `data` key a payload names its destination in.
///
/// This project's convention, not an FCM field — FCM cannot say which screen to
/// open, so it rides in `data` and the client routes on it.
const deepLinkKey = 'deep_link';

/// The shell's destinations, ordered as `AppShell`'s `IndexedStack` builds them.
///
/// Here rather than private to `_AppShellState`, because the deep-link mapping
/// below names the same six and two copies would drift.
///
/// Appended only, never renumbered: a link already in flight names an index, and
/// shifting one would silently send it to the wrong page.
const inboxDestination = 0;
const scenariosDestination = 1;
const sandboxDestination = 2;
const runsDestination = 3;
const telemetryDestination = 4;
const channelsDestination = 5;

/// Where a deep link points — two cases, because one sets the shell's index and
/// the other pushes a route over it.
sealed class DeepLinkDestination {
  const DeepLinkDestination();
}

/// One of the drawer destinations. Nothing is pushed for these — they live in
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
  '/channels': channelsDestination,
};

/// Where [link] points, or null when it names nothing this app has.
///
/// Null is useful rather than a failure: the caller falls back to the message
/// detail page, which already shows the raw link as a data row.
///
/// Never throws — the Sandbox accepts any payload typed into it, and a malformed
/// link must cost the link, not the tap.
DeepLinkDestination? deepLinkDestination(String? link) {
  if (link == null) {
    return null;
  }

  // No destination lives in the query, so dropping it keeps an otherwise valid
  // path working.
  final path = link.trim().split('?').first;
  // One trailing slash tolerated, but not on '/' itself, which would leave an
  // empty string matching nothing.
  final trimmed = path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  if (_paths[trimmed] case final index?) {
    return ShellDestination(index);
  }

  const runsPrefix = '/runs/';
  if (trimmed.startsWith(runsPrefix)) {
    final runId = trimmed.substring(runsPrefix.length);
    // A blank or nested id is not a run, so it falls through to the detail page
    // rather than fetching and showing an error nobody asked for.
    if (runId.isNotEmpty && !runId.contains('/')) {
      return RunTimelineDestination(runId);
    }
  }

  return null;
}
