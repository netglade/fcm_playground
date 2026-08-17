import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains/runs/entities/run_scheduler.dart';
import 'cubit/run_timeline_cubit.dart';
import 'cubit/run_timeline_state.dart';
import 'widgets/run_item_card.dart';

/// One run, item by item, each with its events.
///
/// A pushed route rather than a destination, so it carries its own `Scaffold` and
/// its own back arrow.
class RunTimelinePage extends StatelessWidget {
  const RunTimelinePage({
    required this.scheduler,
    required this.runId,
    super.key,
  });

  final RunScheduler scheduler;

  final String runId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => RunTimelineCubit(scheduler, runId)..load(),
    child: BlocBuilder<RunTimelineCubit, RunTimelineState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Run'),
          actions: [
            IconButton(
              // The arrival of a push is reported by the device, not by this
              // page, so refreshing is how a timeline grows.
              onPressed: context.read<RunTimelineCubit>().load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
            ),
          ],
        ),
        body: switch (state) {
          RunTimelineState(isLoading: true) => const Center(
            child: CircularProgressIndicator(),
          ),
          RunTimelineState(error: final error?) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error),
          ),
          RunTimelineState(run: final run?) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [for (final item in run.items) RunItemCard(item: item)],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    ),
  );
}
