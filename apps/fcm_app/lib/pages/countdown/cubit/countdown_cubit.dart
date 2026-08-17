import 'dart:async';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/runs/entities/run_scheduler.dart';
import '../../../domains/runs/entities/run_scheduler_exception.dart';
import 'countdown_state.dart';

/// Counts the delay down, and cancels the run if asked.
///
/// [ticks] is injected so the tests drive it with a controller and create no real
/// timer — the same reason `SendScheduler` owns none on the server.
class CountdownCubit extends Cubit<CountdownState> {
  CountdownCubit({
    required this._scheduler,
    required this._run,
    required int delaySeconds,
    Stream<void>? ticks,
  }) : super(CountdownState(remainingSeconds: delaySeconds)) {
    _ticks = (ticks ?? Stream<void>.periodic(const Duration(seconds: 1)))
        .listen((_) => _onTick());
  }

  final RunScheduler _scheduler;
  final ScheduledRun _run;
  late final StreamSubscription<void> _ticks;

  String get runId => _run.id;

  /// Cancels whatever of the run has not gone out.
  ///
  /// Nothing is marked cancelled locally unless the API said so: an item already on
  /// its way to FCM is past cancelling, and a screen claiming otherwise would be
  /// contradicted by the timeline a minute later.
  Future<void> cancel() async {
    try {
      await _scheduler.cancel(_run.id);
      await _ticks.cancel();
      emit(state.copyWith(isCancelled: true));
    } on RunSchedulerException catch (error) {
      emit(state.copyWith(error: error.message));
    }
  }

  void _onTick() {
    if (state.isFinished || state.isCancelled) {
      return;
    }

    final remaining = state.remainingSeconds - 1;
    emit(
      state.copyWith(
        remainingSeconds: remaining <= 0 ? 0 : remaining,
        isFinished: remaining <= 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _ticks.cancel();

    return super.close();
  }
}
