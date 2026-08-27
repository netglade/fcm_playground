import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/pages/runs/cubit/run_timeline_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads one run and its events.
class RunTimelineCubit extends Cubit<RunTimelineState> {
  RunTimelineCubit(this._scheduler, this._runId)
    : super(const RunTimelineState());

  final RunScheduler _scheduler;
  final String _runId;

  Future<void> load() async {
    emit(const RunTimelineState());
    try {
      emit(
        RunTimelineState(isLoading: false, run: await _scheduler.fetch(_runId)),
      );
    } on RunSchedulerException catch (error) {
      emit(RunTimelineState(isLoading: false, error: error.message));
    }
  }
}
