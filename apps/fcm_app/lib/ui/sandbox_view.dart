import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'sandbox_form.dart';
import 'scenario_picker.dart';
import 'send_result_card.dart';

/// Composes a push and sends it to this device.
///
/// A `ListView` rather than a `Column`, because the form is taller than a phone
/// once a few data rows are added and the keyboard is up.
class SandboxView extends StatelessWidget {
  const SandboxView({required this.controller, super.key});

  /// The controller this page reads and edits.
  final SandboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Presets', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ScenarioPicker(controller: controller),
        const Divider(height: 32),
        // Keyed on the revision so loading a preset rebuilds the fields from the
        // new draft; typing leaves the revision alone and the cursor with it.
        SandboxForm(
          key: ValueKey(controller.scenarioRevision),
          controller: controller,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: controller.canSend ? controller.send : null,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send to this device'),
        ),
        if (controller.sendBlockedReason case final reason?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SendResultCard(controller.state),
      ],
    ),
  );
}
