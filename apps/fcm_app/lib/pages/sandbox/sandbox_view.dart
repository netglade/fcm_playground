import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../i18n/scenario_text.dart';
import '../../i18n/translations.g.dart';
import 'cubit/sandbox_cubit.dart';
import 'cubit/sandbox_state.dart';
import 'widgets/form/message_section.dart';
import 'widgets/manual_steps_block.dart';
import 'widgets/scenario_needs_banner.dart';
import 'widgets/send_footer.dart';
import 'widgets/send_target_field.dart';

/// Composes a push from a scenario or from scratch, and sends it to this device.
///
/// Arranged around one rule: what the user needs on arrival must not be reachable
/// only by scrolling. Send is pinned in a [SendFooter] below the scrolling form
/// rather than trailing it, because a form that grows by 27 fields when one section
/// opens will bury anything placed after it.
///
/// The page sits in the shell's `IndexedStack`, so that footer cannot be a
/// `Scaffold.bottomNavigationBar`; the `Column` here is what pins it.
class SandboxView extends StatelessWidget {
  const SandboxView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SandboxCubit, SandboxState>(
    builder: (context, state) {
      final t = context.t;

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SendTargetField(),
                const SizedBox(height: 8),
                ScenarioNeedsBanner(scenario: state.selectedScenario),
                if (state.selectedScenario case final scenario?) ...[
                  if (t.scenarioManualSteps(scenario.l10nKey) case final steps?)
                    ManualStepsBlock(steps: steps),
                  if (t.scenarioExpectation(scenario.l10nKey)
                      case final expectation?)
                    Text(expectation),
                  if (scenario.requiresKilledApp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      // The same key the scenario card uses, so the badge reads
                      // identically wherever a scenario names this requirement.
                      child: Text(t.common.needs_killed_app),
                    ),
                  const Divider(height: 32),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.sandbox.validate_only),
                  value: state.validateOnly,
                  onChanged: (value) => context
                      .read<SandboxCubit>()
                      .setValidateOnly(value ?? false),
                ),
                const SizedBox(height: 8),
                // The form itself, not a field of the state: it is mutable and
                // identity-stable, so the sections bind to it directly.
                MessageSection(form: context.read<SandboxCubit>().form),
              ],
            ),
          ),
          const SendFooter(),
        ],
      );
    },
  );
}
