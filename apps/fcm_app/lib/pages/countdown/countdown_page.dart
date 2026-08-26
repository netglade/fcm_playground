import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains/runs/plugin_countdown_screen.dart';
import '../../domains/runs/countdown_screen.dart';
import 'cubit/countdown_cubit.dart';
import 'cubit/countdown_state.dart';
import 'widgets/countdown_body.dart';

/// The screen the user reads while they kill the app.
///
/// It takes a built [cubit] rather than the pieces to build one: the caller has just
/// scheduled the run and holds it, and a page that re-created the cubit on a rebuild
/// would restart the countdown.
///
/// Stateful because it owns the display: [CountdownScreen.keepAwake] on the way in
/// and [CountdownScreen.release] on the way out, which no builder can promise.
class CountdownPage extends StatefulWidget {
  const CountdownPage({
    required this.cubit,
    required this.onFinished,
    this.screen = const PluginCountdownScreen(),
    super.key,
  });

  final CountdownCubit cubit;

  /// Called once the delay has elapsed with the page still alive — which happens
  /// when the user did not kill the app, a legitimate observation rather than a
  /// failure.
  final VoidCallback onFinished;

  final CountdownScreen screen;

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  @override
  void initState() {
    super.initState();
    // Without this the display sleeps on its own timeout, often before the user has
    // finished reading the instruction.
    widget.screen.keepAwake();
  }

  @override
  void dispose() {
    widget.screen.release();
    widget.cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.cubit,
    child: BlocConsumer<CountdownCubit, CountdownState>(
      listener: _onStateChanged,
      builder: (context, state) => CountdownBody(
        state: state,
        screen: widget.screen,
        onCancel: widget.cubit.cancel,
      ),
    ),
  );

  /// A finished countdown hands over; a cancelled one simply leaves.
  void _onStateChanged(BuildContext context, CountdownState state) {
    if (state.isCancelled) {
      Navigator.of(context).pop();

      return;
    }
    if (state.isFinished) {
      widget.onFinished();
    }
  }
}
