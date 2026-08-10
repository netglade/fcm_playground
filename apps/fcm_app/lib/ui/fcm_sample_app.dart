import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'app_shell.dart';

/// Root widget. Takes its state holders as parameters rather than creating
/// them, so widget tests can supply fakes.
class FcmSampleApp extends StatelessWidget {
  const FcmSampleApp({required this.inbox, required this.sandbox, super.key});

  final PushInbox inbox;
  final SandboxController sandbox;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FCM Sample',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: AppShell(inbox: inbox, sandbox: sandbox),
  );
}
