import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'send_result_card.dart';

/// The page's primary action, with whatever is blocking it and whatever came
/// of the last press.
///
/// Lives outside the scrolling payload form on purpose. As the last child of
/// the form's `ListView` it sat below the fold on arrival — a lazily-built list
/// had not even constructed it — and it drifted further down with every section
/// opened, since `android.notification` alone adds 27 fields. Pinned here it is
/// reachable whatever the form's height, and a send result cannot land
/// off-screen either.
///
/// It is a widget of its own rather than a `Widget`-returning helper on
/// [SandboxView] because DCM's `avoid-returning-widgets` forbids the helper.
class SendFooter extends StatelessWidget {
  /// Creates the footer. Reads [controller] directly; something above it is
  /// expected to rebuild it when the controller changes.
  const SendFooter({required this.controller, super.key});

  /// The controller whose send this footer triggers and reports.
  final SandboxController controller;

  @override
  Widget build(BuildContext context) => Padding(
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
          label: Text(_labelFor(controller.target)),
        ),
        SendResultCard(controller.state, validateOnly: controller.validateOnly),
      ],
    ),
  );
}

/// What the button promises, matching the chosen audience.
///
/// The label used to read "Send to this device" unconditionally, which stopped
/// being true the moment a target could be chosen — and where a push goes is the
/// one thing on this page a user cannot check by reading the payload back. A
/// button that names the wrong audience is worse than one that names none.
String _labelFor(SendTarget? target) => switch (target) {
  null => 'Send to this device',
  TokenTarget() => 'Send to that token',
  TopicTarget(:final topic) => 'Send to topic "$topic"',
  ConditionTarget() => 'Send to the condition',
  AllDevicesTarget() => 'Send to every device',
};
