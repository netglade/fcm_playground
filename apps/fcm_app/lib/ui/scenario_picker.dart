import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// The gallery: one chip per preset.
///
/// A preset is a starting point, not a fixed payload — tapping one replaces the
/// form's contents and everything stays editable, which is why these are action
/// chips rather than a selection.
class ScenarioPicker extends StatelessWidget {
  const ScenarioPicker({required this.controller, super.key});

  /// The controller a tapped chip applies its scenario to.
  final SandboxController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final scenario in notificationGallery)
        ActionChip(
          key: ValueKey(scenario.id),
          label: Text(scenario.label),
          tooltip: scenario.description,
          onPressed: () => controller.applyScenario(scenario),
        ),
    ],
  );
}
