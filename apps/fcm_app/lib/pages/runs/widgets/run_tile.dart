import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import 'run_time.dart';

/// One run in the list: how big it was, how it went, and when the next item is due.
class RunTile extends StatelessWidget {
  const RunTile({required this.summary, required this.onTap, super.key});

  final RunSummary summary;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        key: Key('run-${summary.runId}'),
        onTap: onTap,
        title: Text('${summary.itemCount} sends'),
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
              Text('next due ${runTime(due)}'),
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
