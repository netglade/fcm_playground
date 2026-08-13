import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'scenario_card.dart';

/// The gallery of message-payload templates, grouped by the facet of FCM
/// each one demonstrates.
///
/// One [ExpansionTile] per group keeps every template reachable from a
/// single page; only the first group starts open, so the page is still short
/// on arrival — eleven groups holding 66 scenarios would otherwise be a wall.
/// A scenario is a starting point rather than a fixed payload, so tapping its
/// card applies it to [controller] and the fields stay editable afterwards;
/// [onScenarioSelected] fires once that application is done, so this widget owns
/// applying the template and its caller owns whatever happens next — currently,
/// moving to the Sandbox to show it.
///
/// Each scenario is a [ScenarioCard] rather than a bare row, because a scenario
/// carries several lines of its own and an undivided list of them runs together.
class ScenarioGroupList extends StatelessWidget {
  /// Creates the gallery. Tapping a scenario applies it to [controller], then
  /// calls [onScenarioSelected].
  const ScenarioGroupList({
    required this.controller,
    required this.onScenarioSelected,
    super.key,
  });

  /// The controller a tapped scenario is applied to.
  final SandboxController controller;

  /// Called after a tapped scenario has been applied to [controller].
  final VoidCallback onScenarioSelected;

  @override
  Widget build(BuildContext context) {
    final groups = <String>{
      for (final scenario in scenarioGallery) scenario.group,
    };

    return Column(
      children: [
        for (final (index, group) in groups.indexed)
          ExpansionTile(
            title: Text(group),
            initiallyExpanded: index == 0,
            // The cards carry their own margins, so the tile adds none.
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final scenario in scenarioGallery.where(
                (s) => s.group == group,
              ))
                ScenarioCard(
                  scenario: scenario,
                  onTap: () {
                    controller.applyScenario(scenario);
                    onScenarioSelected();
                  },
                ),
            ],
          ),
      ],
    );
  }
}
