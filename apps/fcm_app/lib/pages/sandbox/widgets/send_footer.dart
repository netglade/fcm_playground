import 'dart:async';

import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/countdown/countdown.dart';
import 'package:fcm_app/pages/runs/runs.dart';
import 'package:fcm_app/pages/sandbox/cubit/cubit.dart';
import 'package:fcm_app/pages/sandbox/widgets/schedule_sheet.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_result_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The page's primary action, with whatever is blocking it and whatever came of
/// the last press.
///
/// Lives outside the scrolling payload form on purpose: as the last child of the
/// form's `ListView` it sat below the fold on arrival, and drifted further down
/// with every section opened.
///
/// It subscribes to the [SandboxCubit] `context` provides rather than reading one
/// handed in, so it redraws on its own: Send's enabled state and the result card
/// both follow the cubit, and neither may depend on the page above happening to
/// rebuild.
class SendFooter extends StatelessWidget {
  const SendFooter({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SandboxCubit, SandboxState>(
    builder: (context, state) {
      final controller = context.read<SandboxCubit>();
      final t = context.t;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            if (controller.sendBlockedReason case final reason?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            FilledButton.icon(
              onPressed: controller.canSend ? controller.send : null,
              icon: const Icon(Icons.send_outlined),
              label: Text(_sendLabel(t, state.target)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.canSend
                  ? () => unawaited(_schedule(context, state))
                  : null,
              icon: const Icon(Icons.schedule_outlined),
              // The same key the selection bar uses for its own Schedule button.
              label: Text(t.common.schedule_ellipsis),
            ),
            SendResultCard(
              state.sendState,
              validateOnly: state.validateOnly,
              onNotReceived: controller.reportNotReceived,
            ),
          ],
        ),
      );
    },
  );

  /// Asks for a delay, schedules the run, and opens the countdown on it.
  ///
  /// The countdown counts the *requested* delay rather than the run's `due_at`: the
  /// two clocks disagree in this project as a matter of record, and a foreign clock
  /// is tolerable in a latency figure but not in a number counting down at a person.
  ///
  /// The countdown's cubit is built here, before the push, rather than inside the
  /// route's `builder` — a `builder` can run again on a rebuild, and a cubit built
  /// there would restart the countdown out from under the user.
  Future<void> _schedule(BuildContext context, SandboxState state) async {
    final cubit = context.read<SandboxCubit>();
    final scheduler = context.read<RunScheduler>();
    final active = context.read<ActiveRunStore>();
    final navigator = Navigator.of(context);
    final choice = await showScheduleSheet(
      context,
      initialDelaySeconds: state.selectedScenario?.defaultDelaySeconds ?? 0,
    );
    if (choice == null) {
      return;
    }

    final run = await cubit.schedule(choice.delaySeconds);
    if (run == null) {
      return;
    }

    final countdown = CountdownCubit(
      scheduler: scheduler,
      run: run,
      active: active,
      delaySeconds: choice.delaySeconds,
    );
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CountdownPage(
          cubit: countdown,
          onFinished: () => navigator.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  RunTimelinePage(scheduler: scheduler, runId: run.id),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a push goes is the one thing on this page a user cannot check by reading
/// the payload back, so the button names the audience rather than assuming one.
String _sendLabel(Translations t, SendTarget? target) => switch (target) {
  null => t.send.to_this_device,
  TokenTarget() => t.send.to_that_token,
  TopicTarget(:final topic) => t.send.to_topic(topic: topic),
  ConditionTarget() => t.send.to_condition,
  AllDevicesTarget() => t.send.to_every_device,
};
