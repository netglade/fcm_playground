import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../../../i18n/scenario_text.dart';
import '../../../i18n/translations.g.dart';

/// Says what the loaded scenario still needs before it demonstrates anything, and
/// nothing at all when there is nothing to say.
///
/// It deliberately does not block Send: the push is genuine and valid, only the
/// behaviour it is meant to show is missing.
class ScenarioNeedsBanner extends StatelessWidget {
  const ScenarioNeedsBanner({required this.scenario, super.key});

  /// The loaded scenario, or null when the form was filled in by hand.
  final Scenario? scenario;

  @override
  Widget build(BuildContext context) {
    final needs = scenario?.needs ?? const <ScenarioNeed>[];
    if (needs.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final t = context.t;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          t.sandbox.needs_banner(
            needs: needs.map((need) => t.scenarioNeedLabel(need)).join(', '),
          ),
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
