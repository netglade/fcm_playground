import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';

/// Reports that the push for [traceId] never arrived — the only evidence available
/// when the interesting answer is silence.
///
/// One press per send: a second would record a second `not_received` for one
/// message and inflate the only count a human produces, so the button disables
/// itself and says so rather than quietly ignoring the press.
///
/// The pressed state lives here rather than on `SandboxCubit` because it is a fact
/// about one trace id, not about the page. [didUpdateWidget] resets it when the
/// trace id changes, so a rebuild that swaps the id in place re-enables the button.
class NotReceivedButton extends StatefulWidget {
  const NotReceivedButton({
    required this.traceId,
    required this.onNotReceived,
    super.key,
  });

  final String traceId;

  /// Expected to record *and* flush: this is a foreground action, and the user is
  /// entitled to assume it has been reported.
  final Future<void> Function(String traceId) onNotReceived;

  @override
  State<NotReceivedButton> createState() => _NotReceivedButtonState();
}

class _NotReceivedButtonState extends State<NotReceivedButton> {
  bool _reported = false;

  @override
  void didUpdateWidget(NotReceivedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different trace id is a different message, and what was reported about
    // the previous one says nothing about this one.
    if (oldWidget.traceId != widget.traceId) {
      _reported = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _reported ? null : _report,
        icon: Icon(_reported ? Icons.check : Icons.notifications_off_outlined),
        label: Text(
          _reported ? t.not_received.reported : t.not_received.button,
        ),
      ),
    );
  }

  /// Disables the button before anything is awaited: a flush is a network round
  /// trip, and a second tap while it is in flight would record a second row.
  Future<void> _report() async {
    setState(() => _reported = true);
    await widget.onNotReceived(widget.traceId);
  }
}
