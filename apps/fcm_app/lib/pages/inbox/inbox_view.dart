import 'dart:async';

import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/inbox/cubit/cubit.dart';
import 'package:fcm_app/pages/inbox/message_detail_page.dart';
import 'package:fcm_app/pages/inbox/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lists every push received this session, newest first.
///
/// A body rather than a page: the `Scaffold` and the `AppBar` belong to `AppShell`,
/// so each destination is one widget with no chrome of its own.
class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.setupError case final error?) SetupErrorBanner(error),
          if (state.token case final token?)
            ListTile(
              dense: true,
              leading: const Icon(Icons.key_outlined),
              title: Text(t.inbox.registration_token),
              subtitle: Text(
                token,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              // The way out of an ongoing notification, which cannot be swiped
              // away — and of anything else stuck in the tray. Clears the tray
              // only: the inbox below keeps every message, because the tray and
              // the inbox are different lists.
              onPressed: () =>
                  unawaited(context.read<NotificationPresenter>().clearAll()),
              icon: const Icon(Icons.clear_all_outlined),
              label: Text(t.inbox.clear_notifications),
            ),
          ),
          Expanded(
            child: state.messages.isEmpty
                ? Center(child: Text(t.inbox.empty))
                : ListView.builder(
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) => MessageTile(
                      state.messages[index],
                      onTap: (message) => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => MessageDetailPage(
                            message,
                            pressedAction: state.pressedActions[message.id],
                            reply: state.replies[message.id],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (state.rejections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t.inbox.malformed_dropped(n: state.rejections.length),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
