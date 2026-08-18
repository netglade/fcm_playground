import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains/telemetry/entities/telemetry_reader.dart';
import 'cubit/telemetry_cubit.dart';
import 'cubit/telemetry_state.dart';
import 'widgets/events_tab.dart';
import 'widgets/latency_matrix.dart';

/// What became of every push: the nine events per trace, and the latency matrix.
///
/// The `TabBar` sits in the body rather than in an `AppBar.bottom`, because the shell
/// owns the app bar and every destination shares it. It builds its own cubit, like
/// `RunsView` and unlike the Sandbox: no other page shares this state.
class TelemetryView extends StatelessWidget {
  const TelemetryView({required this.reader, super.key});

  final TelemetryReader reader;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TelemetryCubit(reader)..load(),
    child: DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: TabBar(
                  tabs: [
                    Tab(text: 'Events'),
                    Tab(text: 'Latency'),
                  ],
                ),
              ),
              Builder(
                // The arrival of a push is reported by the device, not by this page,
                // so reloading is how either tab grows.
                builder: (context) => IconButton(
                  onPressed: context.read<TelemetryCubit>().load,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload',
                ),
              ),
            ],
          ),
          Expanded(
            child: BlocBuilder<TelemetryCubit, TelemetryState>(
              builder: (context, state) => switch (state) {
                TelemetryState(isLoading: true) => const Center(
                  child: CircularProgressIndicator(),
                ),
                TelemetryState(error: final error?) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error),
                  ),
                ),
                TelemetryState(:final traces, :final latencies) => TabBarView(
                  children: [
                    EventsTab(traces: traces),
                    LatencyMatrix(rows: latencies),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    ),
  );
}
