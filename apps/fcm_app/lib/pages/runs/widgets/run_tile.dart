import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/runs/widgets/run_time.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One run in the list: how big it was, how it went, and when the next item is due.
class RunTile extends StatelessWidget {
  const RunTile({required this.summary, required this.onTap, super.key});

  final RunSummary summary;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        key: Key('run-${summary.runId}'),
        onTap: onTap,
        title: Text(t.run_tile.sends(n: summary.itemCount)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.runId,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
            ),
            Text(_tally(summary)),
            if (summary.nextDueAt case final due?)
              Text(t.run_tile.next_due(time: runTime(due))),
          ],
        ),
      ),
    );
  }
}

/// Only the states this run holds, so a finished run does not read "0 missed".
String _tally(RunSummary summary) => [
  for (final state in RunItemState.values)
    if (summary.count(state) > 0) '${summary.count(state)} ${state.wireName}',
].join(' · ');
