import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/runs/cubit/cubit.dart';
import 'package:fcm_app/pages/runs/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  Widget build(BuildContext context) {
    final t = context.t;

    return BlocProvider(
      create: (_) => RunTimelineCubit(scheduler, runId)..load(),
      child: BlocBuilder<RunTimelineCubit, RunTimelineState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text(t.run_timeline.title),
            actions: [
              IconButton(
                // The arrival of a push is reported by the device, not by this
                // page, so refreshing is how a timeline grows.
                onPressed: context.read<RunTimelineCubit>().load,
                icon: const Icon(Icons.refresh),
                tooltip: t.common.reload,
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
}
