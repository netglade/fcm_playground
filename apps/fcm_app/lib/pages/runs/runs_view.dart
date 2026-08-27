import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/runs/cubit/cubit.dart';
import 'package:fcm_app/pages/runs/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Every run this API remembers, newest first.
///
/// It builds its own cubit rather than taking one from `context`: unlike the
/// Sandbox, no other page shares this state, and a page-local cubit is discarded
/// with the page.
class RunsView extends StatelessWidget {
  const RunsView({
    required this.scheduler,
    required this.onRunSelected,
    super.key,
  });

  final RunScheduler scheduler;

  /// Called with the tapped run's id. This page does not know where that goes.
  final void Function(String runId) onRunSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return BlocProvider(
      create: (_) => RunsCubit(scheduler)..load(),
      child: BlocBuilder<RunsCubit, RunsState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: context.read<RunsCubit>().load,
          // Always a scrollable, even when it holds one line: RefreshIndicator
          // needs something that scrolls, and pull-to-refresh is the only way
          // back from an error here.
          child: switch (state) {
            RunsState(isLoading: true) => const Center(
              child: CircularProgressIndicator(),
            ),
            RunsState(error: final error?) => ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(padding: const EdgeInsets.all(16), child: Text(error)),
              ],
            ),
            RunsState(runs: []) => ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.runs.empty),
                ),
              ],
            ),
            RunsState(:final runs) => ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final summary in runs)
                  RunTile(
                    summary: summary,
                    onTap: () => onRunSelected(summary.runId),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
