import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/telemetry/cubit/cubit.dart';
import 'package:fcm_app/pages/telemetry/widgets/trace_card.dart';
import 'package:flutter/material.dart';

/// Every trace the API remembers, newest first.
class EventsTab extends StatelessWidget {
  const EventsTab({required this.traces, super.key});

  final List<TraceTimeline> traces;

  @override
  Widget build(BuildContext context) {
    if (traces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.t.telemetry.events.empty),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [for (final timeline in traces) TraceCard(timeline: timeline)],
    );
  }
}
