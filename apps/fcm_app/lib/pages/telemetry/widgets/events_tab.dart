import 'package:flutter/material.dart';

import '../cubit/trace_timeline.dart';
import 'trace_card.dart';

/// Every trace the API remembers, newest first.
class EventsTab extends StatelessWidget {
  const EventsTab({required this.traces, super.key});

  final List<TraceTimeline> traces;

  @override
  Widget build(BuildContext context) {
    if (traces.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nothing recorded yet. Send a push from the Sandbox, then reload.',
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [for (final timeline in traces) TraceCard(timeline: timeline)],
    );
  }
}
