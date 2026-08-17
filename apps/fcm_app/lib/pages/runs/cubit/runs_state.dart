import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// What the Runs list is showing.
///
/// Value-equal, unlike `SandboxState`: nothing here is republished on every
/// keystroke, so dropping a state equal to the current one is exactly right.
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
      _sameIds(runs, other.runs);

  @override
  int get hashCode =>
      Object.hash(isLoading, error, Object.hashAll(runs.map((r) => r.runId)));
}

bool _sameIds(List<RunSummary> a, List<RunSummary> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].runId != b[i].runId || a[i].states.length != b[i].states.length) {
      return false;
    }
  }

  return true;
}
