import 'dart:async';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/runs/entities/active_run_store.dart';
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
    required this._active,
    required int delaySeconds,
    Stream<void>? ticks,
  }) : super(CountdownState(remainingSeconds: delaySeconds)) {
    _ticks = (ticks ?? Stream<void>.periodic(const Duration(seconds: 1)))
        .listen((_) => _onTick());
  }

  final RunScheduler _scheduler;
  final ScheduledRun _run;

  /// Cleared once the user has been shown this run's outcome — by a successful
  /// cancel, or by the countdown reaching zero and handing over to the timeline
  /// — so nothing reopens it unasked at the next launch. `_openAwaitedRun` in
  /// `AppShell` is the only other writer of this id, and it is the one path this
  /// class does not cover: the app being killed mid-countdown, which is exactly
  /// what leaves no cubit alive to clear anything.
  final ActiveRunStore _active;
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
      unawaited(_ticks.cancel());
      // The user is about to be told this run was cancelled — that is the
      // outcome `ActiveRunStore` exists to surface, so there is nothing left
      // for a later launch to reopen.
      await _active.clear();
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
    final finished = remaining <= 0;
    if (finished) {
      // `CountdownPage.onFinished` hands over to the timeline immediately, so
      // this run's outcome has already been shown by the time a later launch
      // could ask `ActiveRunStore` about it.
      unawaited(_active.clear());
    }
    emit(
      state.copyWith(
        remainingSeconds: finished ? 0 : remaining,
        isFinished: finished,
      ),
    );
  }

  @override
  Future<void> close() async {
    unawaited(_ticks.cancel());

    return super.close();
  }
}
