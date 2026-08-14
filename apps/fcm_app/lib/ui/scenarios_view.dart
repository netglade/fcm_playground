import 'package:flutter/material.dart';

import '../sandbox/sandbox_cubit.dart';
import 'scenario_group_list.dart';

/// The scenario gallery's own page.
///
/// The gallery used to sit above the payload editor on the Sandbox page, but
/// together the two are taller than a phone screen, so the editor landed
/// below the fold with nothing editable visible on arrival. Splitting the
/// gallery out fixes that: this page is nothing but the gallery, and picking
/// a scenario here hands off to the Sandbox with the template already
/// applied.
class ScenariosView extends StatelessWidget {
  /// Creates the page. Tapping a scenario applies it to [controller] and
  /// then calls [onScenarioSelected].
  const ScenariosView({
    required this.controller,
    required this.onScenarioSelected,
    super.key,
  });

  /// The controller a tapped scenario is applied to.
  final SandboxCubit controller;

  /// Called once a tapped scenario has been applied, so the caller can move
  /// on — this page does not know what "on" means.
  final VoidCallback onScenarioSelected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ScenarioGroupList(
        controller: controller,
        onScenarioSelected: onScenarioSelected,
      ),
    ],
  );
}
