import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One scenario in the gallery, as a card.
///
/// Cards rather than plain rows because a scenario carries four separate things —
/// a title, what to watch for, a platform caveat and sometimes a killed-app
/// note — and as an undivided list those wrap into each other until it stops
/// being clear where one scenario ends and the next begins. Eleven groups of them
/// makes that worse, not better.
///
/// The id is shown, quietly, because it is how every *other* surface refers to
/// this scenario: the source catalogue is organised by id, the validate-only
/// sweep reports by id, and the tests name ids. A card you cannot tie back to the
/// document is harder to act on than one you can.
class ScenarioCard extends StatelessWidget {
  /// Creates a card for [scenario], calling [onTap] when it is chosen.
  const ScenarioCard({required this.scenario, required this.onTap, super.key});

  /// The scenario this card describes.
  final Scenario scenario;

  /// Called when the card is tapped.
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
        // The chip says only *that* work is outstanding, not which — a row
        // carrying five labels would be unreadable, and which needs they are
        // matters once the scenario is loaded, where ScenarioNeedsBanner names
        // them.
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
