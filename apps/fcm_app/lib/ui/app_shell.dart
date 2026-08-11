import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'inbox_view.dart';
import 'sandbox_view.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer's
/// selection, and one body per destination.
///
/// The destinations sit in an `IndexedStack` so both keep their state — the
/// half-filled Sandbox form survives a look at the inbox — and because a
/// `Widget`-returning helper method would break DCM's `avoid-returning-widgets`.
class AppShell extends StatefulWidget {
  const AppShell({required this.inbox, required this.sandbox, super.key});

  /// The inbox rendered by the "Inbox" destination.
  final PushInbox inbox;

  /// The controller rendered by the "Sandbox" destination.
  final SandboxController sandbox;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = ['Push inbox', 'Sandbox'];

  int _destination = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_titles[_destination])),
    drawer: NavigationDrawer(
      selectedIndex: _destination,
      onDestinationSelected: _select,
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
          child: Text('FCM Sample'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.inbox_outlined),
          label: Text('Inbox'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.science_outlined),
          label: Text('Sandbox'),
        ),
      ],
    ),
    body: IndexedStack(
      index: _destination,
      children: [
        InboxView(inbox: widget.inbox),
        SandboxView(controller: widget.sandbox),
      ],
    ),
  );

  /// Applies the drawer's choice and gets the drawer out of the way, which
  /// `NavigationDrawer` does not do on its own.
  void _select(int index) {
    setState(() => _destination = index);
    Navigator.pop(context);
  }
}
