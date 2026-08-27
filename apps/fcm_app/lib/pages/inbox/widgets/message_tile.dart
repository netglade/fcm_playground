import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:flutter/material.dart';

/// One row in the inbox.
class MessageTile extends StatelessWidget {
  const MessageTile(this.message, {this.onTap, super.key});

  final PushMessage message;

  /// Carries the message rather than an index, so nothing has to look the row up in
  /// a list that may have changed since the build.
  final ValueChanged<PushMessage>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final extras = message.data.keys.join(', ');
    final headline = message.title.isEmpty
        ? t.message_tile.no_title
        : message.title;
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
        extras.isEmpty
            ? message.body
            : t.message_tile.body_with_data(body: message.body, keys: extras),
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
