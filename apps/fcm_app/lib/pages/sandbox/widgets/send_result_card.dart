import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';
import '../cubit/sandbox_send_state.dart';
import 'not_received_button.dart';

/// What became of the last send.
///
/// A validate-only success reads "validated, not sent" rather than borrowing the
/// wording used for a real delivery: telling someone a push arrived when the server
/// only checked the request would be the worst failure this screen could produce.
/// Both ids appear either way — a validated send is traced too, and hiding the id
/// would make half the traces unfindable.
///
/// The [NotReceivedButton] lives inside this switch because it reports against
/// *this* send's trace id, so "appears only after a real send" is decided by the
/// same exhaustive match that decides what the card says.
class SendResultCard extends StatelessWidget {
  const SendResultCard(
    this.state, {
    required this.validateOnly,
    required this.onNotReceived,
    super.key,
  });

  final SandboxSendState state;

  /// The flag as it was for the send that produced [state], so a checkbox toggle
  /// after the fact cannot relabel a result that already happened.
  final bool validateOnly;

  final Future<void> Function(String traceId) onNotReceived;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.t;

    return switch (state) {
      SandboxIdle() => const SizedBox.shrink(),
      SandboxSending() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      SandboxSent(:final response) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              validateOnly
                  ? t.send_result.validated(
                      messageId: response.messageId,
                      traceId: response.traceId,
                    )
                  : t.send_result.sent(
                      messageId: response.messageId,
                      traceId: response.traceId,
                    ),
              style: TextStyle(color: colors.primary),
            ),
            // Not for a validated send: nothing was delivered, and the API
            // records `sent` for a validation too, which would make the report
            // indistinguishable from a genuine drop.
            if (!validateOnly)
              NotReceivedButton(
                traceId: response.traceId,
                onNotReceived: onNotReceived,
              ),
          ],
        ),
      ),
      SandboxScheduled(:final run) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          t.send_result.scheduled(n: run.items.length, runId: run.id),
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
