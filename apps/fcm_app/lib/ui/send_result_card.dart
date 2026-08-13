import 'package:flutter/material.dart';

import '../sandbox/sandbox_send_state.dart';

/// What became of the last send.
///
/// Distinguishes a validating send from a real one: telling someone a push
/// arrived when the server only checked the request would be the worst
/// failure this screen could produce, so a validate-only success reads
/// "validated, not sent" rather than borrowing the wording used for a real
/// delivery. Shows the payload id on success, because that is the value the
/// inbox will display — it is what turns "the API said 200" into "this push
/// is mine" — and the trace id beside it, because that is the handle for asking
/// later what became of this send. Both ids appear whether the send was real or
/// only validated: a validated send is traced too, and hiding the id would make
/// half the traces unfindable.
class SendResultCard extends StatelessWidget {
  /// Creates the card. [validateOnly] reflects the flag as it was for the
  /// send that produced [state], so a stale checkbox toggle after the fact
  /// cannot relabel a result that already happened.
  const SendResultCard(this.state, {required this.validateOnly, super.key});

  /// The outcome to render.
  final SandboxSendState state;

  /// Whether the send that produced [state] only validated the request.
  final bool validateOnly;

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
          validateOnly
              ? '✓ Validated · message ${response.messageId} · trace '
                    '${response.traceId} · the payload was validated, not sent'
              : '✓ Sent · message ${response.messageId} · trace '
                    '${response.traceId} · it should appear in the Inbox '
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
