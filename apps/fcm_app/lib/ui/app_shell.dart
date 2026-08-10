import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'app_destination.dart';
import 'app_drawer.dart';
import 'inbox_view.dart';
import 'sandbox_view.dart';

/// The one `Scaffold` in the app.
///
/// Owning the app bar and the drawer here means each destination is a plain
/// body widget with no chrome of its own, and the title cannot drift out of
/// step with what is showing.
class AppShell extends StatefulWidget {
  const AppShell({required this.inbox, required this.sandbox, super.key});

  final PushInbox inbox;
  final SandboxController sandbox;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppDestination _destination = AppDestination.inbox;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    drawer: AppDrawer(selected: _destination, onSelected: _select),
    body: switch (_destination) {
      AppDestination.inbox => InboxView(inbox: widget.inbox),
      AppDestination.sandbox => SandboxView(controller: widget.sandbox),
    },
  );

  String get _title => switch (_destination) {
    AppDestination.inbox => 'Push inbox',
    AppDestination.sandbox => 'Sandbox',
  };

  void _select(AppDestination destination) {
    setState(() => _destination = destination);
    Navigator.of(context).pop();
  }
}
