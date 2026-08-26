import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../domains/push/entities/pressed_action.dart';
import '../../i18n/translations.g.dart';

/// One received message in full.
///
/// A page rather than a destination, pushed over the shell, because it is reached
/// from two places that both mean "look at this one message": an inbox row, and a
/// notification the user tapped.
class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage(
    this.message, {
    this.pressedAction,
    this.reply,
    super.key,
  });

  final PushMessage message;

  /// The action button this message's notification was opened by, if it was.
  ///
  /// Passed in rather than read from a store, so this page stays a
  /// `StatelessWidget` that both its call sites can build from state they
  /// already hold.
  final PressedAction? pressedAction;

  /// The reply the user typed into this message's notification, if any.
  ///
  /// Passed in for the same reason as [pressedAction]: this page stays a
  /// `StatelessWidget` built from state its call sites already hold, rather
  /// than one that reaches into a store of its own.
  final String? reply;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
            if (pressedAction case final pressed?)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.message_detail.opened_by_action(
                          label: notificationActionLabel(
                            message.data[notificationActionsKey],
                            pressed.actionId,
                          ),
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        t.message_detail.from(from: pressed.from.wireName),
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (reply case final text?)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t.message_detail.replied(text: text),
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            Text(message.body, style: theme.textTheme.bodyLarge),
            const Divider(height: 32),
            Text(t.message_detail.sent, style: theme.textTheme.labelMedium),
            Text(message.sentAt.toIso8601String()),
            const SizedBox(height: 16),
            Text(
              t.message_detail.payload_id,
              style: theme.textTheme.labelMedium,
            ),
            Text(message.id),
            const Divider(height: 32),
            Text(
              t.message_detail.extra_data,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            if (message.data.isEmpty)
              Text(t.message_detail.no_extra_data)
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
