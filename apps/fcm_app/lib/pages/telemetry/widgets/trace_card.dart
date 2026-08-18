import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../cubit/trace_timeline.dart';
import 'event_row.dart';

/// One trace, with all nine event types listed whether or not they arrived.
///
/// All nine, because the absences are the interesting part: a card that listed only
/// what happened could not answer "was this one ever displayed?". Absence is drawn
/// neutrally rather than as a failure, since most absences are correct — a data-only
/// push has no `displayed`, a notification-only push has no `received_bg`, and a
/// notification nobody swiped has no `dismissed`.
class TraceCard extends StatelessWidget {
  const TraceCard({required this.timeline, super.key});

  final TraceTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeline.traceId,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            Text(
              '${timeline.scenarioId ?? 'no scenario'} · '
              '${timeline.deviceId ?? 'no device yet'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 16),
            for (final type in TelemetryEventType.values)
              EventRow(type: type, event: timeline.eventOf(type)),
          ],
        ),
      ),
    );
  }
}
