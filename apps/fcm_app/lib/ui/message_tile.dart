import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// One row in the inbox.
class MessageTile extends StatelessWidget {
  const MessageTile(this.message, {this.onTap, super.key});

  /// The message this row shows.
  final PushMessage message;

  /// Called with [message] when the row is tapped, or null to make the row inert.
  ///
  /// It carries the message rather than an index, so nothing has to look the row
  /// up in a list that may have changed since the build.
  final ValueChanged<PushMessage>? onTap;

  @override
  Widget build(BuildContext context) {
    final extras = message.data.keys.join(', ');
    final headline = message.title.isEmpty ? '(no title)' : message.title;
    final tap = onTap;

    return ListTile(
      onTap: tap == null ? null : () => tap(message),
      leading: const Icon(Icons.notifications_outlined),
      title: Text(
        headline,
        style: message.title.isEmpty
            ? TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.outline,
              )
            : null,
      ),
      subtitle: Text(
        extras.isEmpty ? message.body : '${message.body}\ndata: $extras',
      ),
      isThreeLine: extras.isNotEmpty,
      trailing: Text(_formatClockTime(message.sentAt)),
    );
  }
}

/// `HH:MM` in UTC. Deliberately not localised — the sample has no intl setup.
String _formatClockTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
