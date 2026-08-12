import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'payload_editor.dart';
import 'send_result_card.dart';

/// Composes a push from a scenario or from scratch, and sends it to this
/// device.
///
/// Nothing sits above the editor: the gallery that used to open this page
/// lived here too, but the two together were taller than a phone screen,
/// which pushed the editor below the fold with no editable field visible on
/// arrival. The gallery now has its own page (`ScenariosView`) and hands off
/// here with a template already applied, so this page only needs to say
/// which one.
class SandboxView extends StatelessWidget {
  /// Creates the page. Reads and edits [controller] directly, and rebuilds
  /// whenever it changes.
  const SandboxView({required this.controller, super.key});

  /// The controller this page reads and edits.
  final SandboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (controller.selectedScenario case final scenario?) ...[
          Text(scenario.title, style: Theme.of(context).textTheme.titleMedium),
          if (scenario.expectation case final expectation?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(expectation),
            ),
          if (scenario.requiresKilledApp)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Needs the app killed'),
            ),
          const Divider(height: 32),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Validate only'),
          value: controller.validateOnly,
          onChanged: (value) => controller.setValidateOnly(value ?? false),
        ),
        const SizedBox(height: 8),
        // Keyed on the revision so loading a scenario rebuilds the field from
        // the new draft; typing leaves the revision alone and the cursor
        // with it.
        PayloadEditor(
          key: ValueKey(controller.scenarioRevision),
          controller: controller,
        ),
        if (controller.parseError case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
        SendResultCard(controller.state, validateOnly: controller.validateOnly),
      ],
    ),
  );
}
