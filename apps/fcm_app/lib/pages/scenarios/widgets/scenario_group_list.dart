import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../sandbox/cubit/sandbox_cubit.dart';
import 'scenario_card.dart';

/// The gallery of message-payload templates, grouped by the facet of FCM each one
/// demonstrates.
///
/// Only the first group starts open — eleven groups holding 66 scenarios would
/// otherwise be a wall. A scenario is a starting point rather than a fixed payload,
/// so tapping its card applies it to the [SandboxCubit] `context` provides and the
/// fields stay editable afterwards.
class ScenarioGroupList extends StatelessWidget {
  const ScenarioGroupList({required this.onScenarioSelected, super.key});

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
                    context.read<SandboxCubit>().applyScenario(scenario);
                    onScenarioSelected();
                  },
                ),
            ],
          ),
      ],
    );
  }
}
