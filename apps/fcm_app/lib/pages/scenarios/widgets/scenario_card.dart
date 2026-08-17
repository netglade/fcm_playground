import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One scenario in the gallery, as a card.
///
/// The id is shown, quietly, because it is how every *other* surface refers to this
/// scenario: the source catalogue, the validate-only sweep and the tests all name
/// ids.
class ScenarioCard extends StatelessWidget {
  const ScenarioCard({required this.scenario, required this.onTap, super.key});

  final Scenario scenario;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        title: Text(scenario.title),
        // Only *that* work is outstanding, not which: ScenarioNeedsBanner names
        // them once the scenario is loaded.
        trailing: scenario.isSupported
            ? null
            : const Chip(label: Text('needs work')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.id,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(scenario.description),
            if (scenario.expectation case final expectation?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 4),
                      child: Icon(Icons.warning_amber_outlined, size: 16),
                    ),
                    Expanded(child: Text(expectation)),
                  ],
                ),
              ),
            if (scenario.requiresKilledApp)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Needs the app killed'),
              ),
          ],
        ),
      ),
    );
  }
}
