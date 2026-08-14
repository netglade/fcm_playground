import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_cubit.dart';
import 'app_shell.dart';

/// Root widget. Takes the [PushInbox] and the [SandboxCubit] as parameters
/// rather than creating them, so widget tests can supply an inbox wired to a fake
/// source and a sandbox wired to a fake sender.
class FcmSampleApp extends StatelessWidget {
  const FcmSampleApp({required this.inbox, required this.sandbox, super.key});

  /// The inbox handed down to [AppShell].
  final PushInbox inbox;

  /// The sandbox controller handed down to [AppShell].
  final SandboxCubit sandbox;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FCM Sample',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: AppShell(inbox: inbox, sandbox: sandbox),
  );
}
