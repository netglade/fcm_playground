import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/runs/run_scheduler.dart';
import '../../../domains/runs/run_scheduler_exception.dart';
import 'runs_state.dart';

/// Loads the recent runs.
///
/// A failure here is expected rather than exceptional — the API is a local process
/// somebody has to have started — so it becomes a message on the screen instead of
/// an unhandled error.
class RunsCubit extends Cubit<RunsState> {
  RunsCubit(this._scheduler) : super(const RunsState());

  final RunScheduler _scheduler;

  Future<void> load() async {
    emit(const RunsState());
    try {
      emit(RunsState(isLoading: false, runs: await _scheduler.list()));
    } on RunSchedulerException catch (error) {
      emit(RunsState(isLoading: false, error: error.message));
    }
  }
}
