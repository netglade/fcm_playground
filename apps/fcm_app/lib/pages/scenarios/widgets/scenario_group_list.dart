import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/cubit/cubit.dart';
import 'package:fcm_app/pages/scenarios/widgets/scenario_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The gallery of message-payload templates, grouped by the facet of FCM each one
/// demonstrates.
///
/// Only the first group starts open — eleven groups holding 66 scenarios would
/// otherwise be a wall. A scenario is a starting point rather than a fixed payload,
/// so tapping its card applies it to the [SandboxCubit] `context` provides and the
/// fields stay editable afterwards.
class ScenarioGroupList extends StatelessWidget {
  const ScenarioGroupList({
    required this.onScenarioSelected,
    this.selectedIds,
    this.onSelectionChanged,
    super.key,
  });

  final VoidCallback onScenarioSelected;

  /// Null outside selection mode.
  final Set<String>? selectedIds;

  final void Function(String id, bool isSelected)? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final groups = <String>{
      for (final scenario in scenarioGallery) scenario.group,
    };

    return Column(
      children: [
        for (final (index, group) in groups.indexed)
          ExpansionTile(
            key: Key('group-$group'),
            title: Text(t.scenarioGroupName(group)),
            initiallyExpanded: index == 0,
            // The cards carry their own margins, so the tile adds none.
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final scenario in scenarioGallery.where(
                (s) => s.group == group,
              ))
                ScenarioCard(
                  scenario: scenario,
                  isSelected: selectedIds?.contains(scenario.id),
                  onSelectionChanged: (isSelected) =>
                      onSelectionChanged?.call(scenario.id, isSelected),
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
