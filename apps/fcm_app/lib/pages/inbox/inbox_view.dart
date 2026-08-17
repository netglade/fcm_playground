import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../push/inbox_cubit.dart';
import '../push/inbox_state.dart';
import 'message_detail_page.dart';
import 'message_tile.dart';
import 'setup_error_banner.dart';

/// Lists every push received this session, newest first.
///
/// A body rather than a page: the `Scaffold` and the `AppBar` belong to
/// `AppShell`, so each destination is one widget with no chrome of its own.
class InboxView extends StatelessWidget {
  const InboxView({required this.inbox, super.key});

  final InboxCubit inbox;

  @override
  Widget build(BuildContext context) => BlocBuilder<InboxCubit, InboxState>(
    bloc: inbox,
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
                        builder: (_) => MessageDetailPage(message),
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
