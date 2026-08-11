import 'package:flutter/material.dart';

import '../sandbox/sandbox_send_state.dart';

/// What became of the last send.
///
/// Shows the payload id on success, because that is the value the inbox will
/// display — it is what turns "the API said 200" into "this push is mine".
class SendResultCard extends StatelessWidget {
  const SendResultCard(this.state, {super.key});

  /// The outcome to render.
  final SandboxSendState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (state) {
      SandboxIdle() => const SizedBox.shrink(),
      SandboxSending() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      SandboxSent(:final response) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          '✓ Sent · id ${response.payloadId} · it should appear in the Inbox '
          'shortly',
          style: TextStyle(color: colors.primary),
        ),
      ),
      SandboxFailed(:final message) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ColoredBox(
          color: colors.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ),
      ),
    };
  }
}
