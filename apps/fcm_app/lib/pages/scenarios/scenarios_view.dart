import 'package:flutter/material.dart';

import 'widgets/scenario_group_list.dart';

/// The scenario gallery's own page: picking a scenario here hands off to the
/// Sandbox with the template already applied.
class ScenariosView extends StatelessWidget {
  const ScenariosView({required this.onScenarioSelected, super.key});

  /// Called once a tapped scenario has been applied, so the caller can move on —
  /// this page does not know what "on" means.
  final VoidCallback onScenarioSelected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [ScenarioGroupList(onScenarioSelected: onScenarioSelected)],
  );
}
