import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/telemetry/cubit/cubit.dart';
import 'package:fcm_app/pages/telemetry/widgets/event_row.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One trace, with all ten event types listed whether or not they arrived.
///
/// All ten, because the absences are the interesting part: a card that listed only
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
    final t = context.t;

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
              '${timeline.scenarioId ?? t.common.no_scenario} · '
              '${timeline.deviceId ?? t.common.no_device_yet}',
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
