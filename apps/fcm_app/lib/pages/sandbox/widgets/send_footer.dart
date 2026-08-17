import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sandbox_cubit.dart';
import '../cubit/sandbox_state.dart';
import 'send_result_card.dart';

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
              label: Text(_labelFor(state.target)),
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
}

/// Where a push goes is the one thing on this page a user cannot check by reading
/// the payload back, so the button names the audience rather than assuming one.
String _labelFor(SendTarget? target) => switch (target) {
  null => 'Send to this device',
  TokenTarget() => 'Send to that token',
  TopicTarget(:final topic) => 'Send to topic "$topic"',
  ConditionTarget() => 'Send to the condition',
  AllDevicesTarget() => 'Send to every device',
};
