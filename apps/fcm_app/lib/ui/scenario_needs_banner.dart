import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// Says what the loaded scenario still needs before it demonstrates anything.
///
/// Renders nothing when there is nothing to say — no scenario, or one that works
/// today, which is 21 of the 66. A banner on every scenario would be noise, and
/// noise trains people to stop reading banners.
///
/// It deliberately does **not** block Send. The push is genuine and valid; only
/// the behaviour it is meant to show is missing, and watching a client with no
/// action support receive an action payload is itself worth seeing.
class ScenarioNeedsBanner extends StatelessWidget {
  /// Reports [scenario]'s unmet needs, if it has any.
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

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Needs ${needs.map((need) => need.label).join(', ')}. '
          'The push will still be sent, but this scenario cannot be observed '
          'yet.',
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
