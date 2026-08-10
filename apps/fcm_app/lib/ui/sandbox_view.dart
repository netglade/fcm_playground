import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'delivery_fields.dart';
import 'draft_form_fields.dart';
import 'extra_data_editor.dart';
import 'scenario_gallery.dart';
import 'send_result_card.dart';

/// Compose a notification and send it to this device.
///
/// The three editors are keyed on the controller's scenario generation, so
/// applying a preset reseeds their inputs and ordinary typing does not.
///
/// [DraftFormFields] and [ExtraDataEditor] are direct siblings inside this
/// `ListView`'s child list, which is built fresh on every rebuild. Its
/// underlying `SliverChildListDelegate` resolves a keyed child's new position
/// with `_findChildIndex`, a lookup keyed by raw `Key` value with no regard
/// for widget type — unlike `Column`/`Row`, which key-match through
/// `Widget.canUpdate` (type *and* key together). Two sibling widgets sharing
/// one `Key` value here get their identities swapped by that lookup on every
/// rebuild, which tears down and rebuilds whichever loses the swap — silently
/// discarding, for example, an extra-data row the user just added but hasn't
/// typed a key into yet. Salting each key with which editor it seeds keeps
/// the values distinct while preserving the reseed-on-scenario, untouched-
/// while-typing behaviour the shared counter is there for.
class SandboxView extends StatelessWidget {
  const SandboxView({required this.controller, super.key});

  final SandboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final generation = controller.scenarioGeneration;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScenarioGallery(
            selectedEvent: controller.draft.event,
            onSelected: controller.applyScenario,
          ),
          const SizedBox(height: 16),
          DraftFormFields(
            key: ValueKey('draft-$generation'),
            draft: controller.draft,
            problems: controller.problems,
            onChanged: controller.editDraft,
          ),
          const SizedBox(height: 8),
          DeliveryFields(
            draft: controller.draft,
            onChanged: controller.editDraft,
          ),
          const SizedBox(height: 8),
          ExtraDataEditor(
            key: ValueKey('extra-$generation'),
            draft: controller.draft,
            onChanged: controller.editDraft,
          ),
          if (controller.problems.any((problem) => problem.field == 'data'))
            Text(
              controller.problems
                  .firstWhere((problem) => problem.field == 'data')
                  .reason,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.canSend ? controller.send : null,
            icon: const Icon(Icons.send_outlined),
            label: Text(
              controller.isSending ? 'Sending…' : 'Send to this device',
            ),
          ),
          if (controller.token == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No registration token yet.',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          SendResultCard(
            response: controller.lastResponse,
            error: controller.lastError,
          ),
        ],
      );
    },
  );
}
