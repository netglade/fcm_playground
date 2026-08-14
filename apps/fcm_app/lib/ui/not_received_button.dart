import 'package:flutter/material.dart';

/// Reports that the push for [traceId] never arrived.
///
/// The ninth event and the only one a human asserts. Every other event needs
/// something to have happened; this is the only evidence available when the
/// interesting answer is silence, because a message that was never delivered
/// leaves nothing on the device to observe.
///
/// **One press per send.** A second press would record a second `not_received`
/// for one message and inflate the only count a human produces, so the button
/// disables itself and says it has reported rather than staying pressable — a
/// button that quietly ignores a press is indistinguishable from one that
/// worked.
///
/// The pressed state lives here rather than on `SandboxController` because it is
/// a fact about one trace id, not about the page: the controller would need a
/// second thing to invalidate in step with its send state, and a flag left set
/// across a send would silently lose a real report. [didUpdateWidget] resets it
/// when the trace id changes, so a rebuild that swaps the id in place re-enables
/// the button without relying on the card unmounting it first.
class NotReceivedButton extends StatefulWidget {
  /// Creates the button. [onNotReceived] is handed the trace id it reports
  /// against, so the caller cannot report a different one than was displayed.
  const NotReceivedButton({
    required this.traceId,
    required this.onNotReceived,
    super.key,
  });

  /// The trace id of the send this reports against.
  final String traceId;

  /// Records the report. Expected to record *and* flush: this is a foreground
  /// action, and the user is entitled to assume it has been reported.
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
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: _reported ? null : _report,
      icon: Icon(_reported ? Icons.check : Icons.notifications_off_outlined),
      label: Text(_reported ? 'Reported as never arrived' : 'It never arrived'),
    ),
  );

  /// Records the report, disabling the button before anything is awaited.
  ///
  /// The order matters: a flush is a network round trip, and a second tap while
  /// it is in flight would record a second row for one message.
  Future<void> _report() async {
    setState(() => _reported = true);
    await widget.onNotReceived(widget.traceId);
  }
}
