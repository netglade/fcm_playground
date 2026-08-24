import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/inbox_cubit.dart';
import 'cubit/inbox_state.dart';
import 'message_detail_page.dart';
import 'widgets/message_tile.dart';
import 'widgets/setup_error_banner.dart';

/// Lists every push received this session, newest first.
///
/// A body rather than a page: the `Scaffold` and the `AppBar` belong to `AppShell`,
/// so each destination is one widget with no chrome of its own.
class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<InboxCubit, InboxState>(
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.setupError case final error?) SetupErrorBanner(error),
        if (state.token case final token?)
          ListTile(
            dense: true,
            leading: const Icon(Icons.key_outlined),
            title: const Text('Registration token'),
            subtitle: Text(token, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        Expanded(
          child: state.messages.isEmpty
              ? const Center(child: Text('No pushes received yet.'))
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
              '${state.rejections.length} malformed payload(s) dropped',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    ),
  );
}
