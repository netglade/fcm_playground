import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import 'run_time.dart';

/// One item of a run, with its events underneath it — the timeline.
class RunItemCard extends StatelessWidget {
  const RunItemCard({required this.item, super.key});

  final ScheduledRunItem item;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.request.scenarioId ?? '(composed by hand)',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Chip(label: Text(item.state.wireName)),
              ],
            ),
            Text(
              'due ${runTime(item.dueAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (item.error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const Divider(),
            // An empty timeline is said out loud: for a killed app the arrival
            // event is buffered on the device and only reaches the API at the next
            // launch, so "nothing yet" is a real and expected answer.
            if (item.events.isEmpty)
              const Text('Nothing recorded yet.')
            else
              for (final event in item.events)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(event.type.wireName)),
                      Text(runTime(event.at), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
