import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One scenario in the gallery, as a card.
///
/// The id is shown, quietly, because it is how every *other* surface refers to this
/// scenario: the source catalogue, the validate-only sweep and the tests all name
/// ids.
class ScenarioCard extends StatelessWidget {
  const ScenarioCard({
    required this.scenario,
    required this.onTap,
    this.isSelected,
    this.onSelectionChanged,
    super.key,
  });

  final Scenario scenario;

  final VoidCallback onTap;

  /// Null outside selection mode, which is what decides whether a checkbox is
  /// drawn — a bool could not tell "not selecting" from "selecting, unticked".
  final bool? isSelected;

  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('scenario-${scenario.id}'),
        onTap: isSelected == null
            ? onTap
            : () => onSelectionChanged?.call(!isSelected!),
        leading: isSelected == null
            ? null
            : Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged?.call(value ?? false),
              ),
        title: Text(t.scenarioTitle(scenario.l10nKey)),
        // Only *that* work is outstanding, not which: ScenarioNeedsBanner names
        // them once the scenario is loaded.
        trailing: scenario.isSupported
            ? null
            : Chip(label: Text(t.scenario_card.needs_work)),
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
            Text(t.scenarioDescription(scenario.l10nKey)),
            if (t.scenarioExpectation(scenario.l10nKey) case final expectation?)
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t.common.needs_killed_app),
              ),
          ],
        ),
      ),
    );
  }
}
