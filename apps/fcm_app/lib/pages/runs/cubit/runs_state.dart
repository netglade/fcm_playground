import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// What the Runs list is showing.
///
/// Value-equal, unlike `SandboxState`: nothing here is republished on every
/// keystroke, so dropping a state equal to the current one is exactly right.
/// Two states compare equal only when they hold the same run ids in the same
/// order, each with an identical state tally — the counts inside `states`,
/// not merely how many distinct states are present — and the same
/// `nextDueAt`: everything a `RunTile` actually draws.
class RunsState {
  const RunsState({this.isLoading = true, this.runs = const [], this.error});

  final bool isLoading;

  final List<RunSummary> runs;

  /// Safe to show as-is, or null when the load worked.
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is RunsState &&
      isLoading == other.isLoading &&
      error == other.error &&
      _sameRuns(runs, other.runs);

  @override
  int get hashCode =>
      Object.hash(isLoading, error, Object.hashAll(runs.map(_hashRun)));
}

bool _sameRuns(List<RunSummary> a, List<RunSummary> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].runId != b[i].runId ||
        a[i].nextDueAt != b[i].nextDueAt ||
        !_sameTally(a[i].states, b[i].states)) {
      return false;
    }
  }

  return true;
}

/// Equal only when both maps hold the same states with the same counts.
///
/// `collection`'s `MapEquality` would say this directly, but it is only a
/// transitive dependency of this app — not one declared in its pubspec — so
/// it is compared by hand rather than added as a dependency for one check.
bool _sameTally(Map<RunItemState, int> a, Map<RunItemState, int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

int _hashRun(RunSummary run) => Object.hash(
  run.runId,
  run.nextDueAt,
  Object.hashAllUnordered([
    for (final entry in run.states.entries) Object.hash(entry.key, entry.value),
  ]),
);
