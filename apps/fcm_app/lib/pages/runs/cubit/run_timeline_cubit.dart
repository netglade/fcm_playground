import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/runs/entities/run_scheduler.dart';
import '../../../domains/runs/entities/run_scheduler_exception.dart';
import 'run_timeline_state.dart';

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
