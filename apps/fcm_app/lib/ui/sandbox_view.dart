import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../sandbox/sandbox_cubit.dart';
import '../sandbox/sandbox_state.dart';
import 'form/sections/message_section.dart';
import 'manual_steps_block.dart';
import 'scenario_needs_banner.dart';
import 'send_footer.dart';
import 'send_target_field.dart';

/// Composes a push from a scenario or from scratch, and sends it to this
/// device.
///
/// Everything on this page is arranged around one rule: what the user needs on
/// arrival must not be reachable only by scrolling. Only the one-line
/// [SendTargetField] sits above the form, because the gallery that used to open
/// this page lived here too and the two together were taller than a phone
/// screen, which left no editable field visible; the gallery now has its own
/// page (`ScenariosView`) and hands off here with a template already applied, so
/// this page only needs to say which one. And Send is pinned in a [SendFooter]
/// below the scrolling form rather
/// than trailing it, because a form that grows by 27 fields when one section
/// opens will bury anything placed after it.
///
/// The page sits in the shell's `IndexedStack`, so that footer cannot be a
/// `Scaffold.bottomNavigationBar`; the `Column` here is what pins it.
class SandboxView extends StatelessWidget {
  /// Creates the page. Reads and edits [controller] directly, and rebuilds
  /// whenever it emits.
  const SandboxView({required this.controller, super.key});

  /// The cubit this page reads and edits.
  final SandboxCubit controller;

  @override
  Widget build(BuildContext context) => BlocBuilder<SandboxCubit, SandboxState>(
    bloc: controller,
    builder: (_, state) => Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SendTargetField(controller: controller),
              const SizedBox(height: 8),
              ScenarioNeedsBanner(scenario: state.selectedScenario),
              if (state.selectedScenario?.manualSteps case final steps?)
                ManualStepsBlock(steps: steps),
              if (state.selectedScenario case final scenario?) ...[
                if (scenario.expectation case final expectation?)
                  Text(expectation),
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
                value: state.validateOnly,
                onChanged: (value) =>
                    controller.setValidateOnly(value ?? false),
              ),
              const SizedBox(height: 8),
              MessageSection(form: controller.form),
            ],
          ),
        ),
        SendFooter(controller: controller),
      ],
    ),
  );
}
