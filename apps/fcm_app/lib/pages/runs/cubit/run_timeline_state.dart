import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// One run, as the timeline page reads it.
class RunTimelineState {
  const RunTimelineState({this.isLoading = true, this.run, this.error});

  final bool isLoading;

  final ScheduledRun? run;

  final String? error;

  @override
  bool operator ==(Object other) =>
      other is RunTimelineState &&
      isLoading == other.isLoading &&
      error == other.error &&
      run?.id == other.run?.id &&
      _states(run) == _states(other.run);

  @override
  int get hashCode => Object.hash(isLoading, error, run?.id, _states(run));
}

/// The states as one string, so a reload that changed an item redraws while one
/// that changed nothing does not.
String _states(ScheduledRun? run) =>
    run?.items.map((i) => i.state.wireName).join(',') ?? '';
