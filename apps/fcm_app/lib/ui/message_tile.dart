import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// One row in the inbox.
class MessageTile extends StatelessWidget {
  const MessageTile(this.message, {super.key});

  final PushMessage message;

  @override
  Widget build(BuildContext context) {
    final extras = message.data.keys.join(', ');

    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(message.title),
      // `message.id` is the payload id the sandbox reports as `Sent · id
      // sandbox-…`; showing it here is what lets that report be matched
      // against what actually arrived.
      subtitle: Text(
        extras.isEmpty
            ? '${message.body}\nid: ${message.id}'
            : '${message.body}\nid: ${message.id}\ndata: $extras',
      ),
      isThreeLine: true,
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
