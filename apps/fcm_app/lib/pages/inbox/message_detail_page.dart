import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// One received message in full.
///
/// A page rather than a destination, pushed over the shell, because it is reached
/// from two places that both mean "look at this one message": an inbox row, and a
/// notification the user tapped.
class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage(this.message, {super.key});

  final PushMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(message.title)),
      // top: false — the AppBar covers that. The bottom matters because a long
      // payload's last data row would otherwise end under the gesture bar.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(message.body, style: theme.textTheme.bodyLarge),
            const Divider(height: 32),
            Text('Sent', style: theme.textTheme.labelMedium),
            Text(message.sentAt.toIso8601String()),
            const SizedBox(height: 16),
            Text('Payload id', style: theme.textTheme.labelMedium),
            Text(message.id),
            const Divider(height: 32),
            Text('Extra data', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            if (message.data.isEmpty)
              const Text('No extra data keys.')
            else
              for (final entry in message.data.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          entry.key,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
