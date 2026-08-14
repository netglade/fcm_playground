import 'dart:async';

import 'package:flutter/material.dart';

import '../push/inbox_cubit.dart';
import '../push/inbox_state.dart';
import '../sandbox/sandbox_cubit.dart';
import 'inbox_view.dart';
import 'message_detail_page.dart';
import 'sandbox_view.dart';
import 'scenarios_view.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer's
/// selection, and one body per destination.
///
/// The destinations sit in an `IndexedStack` so all three keep their state —
/// the half-filled Sandbox form survives a look at the inbox or the gallery —
/// and because a `Widget`-returning helper method would break DCM's
/// `avoid-returning-widgets`.
class AppShell extends StatefulWidget {
  const AppShell({required this.inbox, required this.sandbox, super.key});

  /// The inbox rendered by the "Inbox" destination.
  final InboxCubit inbox;

  /// The controller rendered by the "Sandbox" destination.
  final SandboxCubit sandbox;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = ['Push inbox', 'Scenarios', 'Sandbox'];
  static const _inboxDestination = 0;
  static const _sandboxDestination = 2;

  late final AppLifecycleListener _lifecycle;
  // A subscription rather than a listener, because the inbox is a cubit now. It
  // stays a side-effect watcher — routing a tap is not painting — which is what
  // `BlocListener` will replace it with once the tree reads its cubits from
  // context.
  late final StreamSubscription<InboxState> _inboxChanges;

  int _destination = _inboxDestination;

  @override
  void initState() {
    super.initState();
    _inboxChanges = widget.inbox.stream.listen(_onInboxChanged);
    // A push that arrived while the app was merely backgrounded sits in the
    // pending key until something drains it, and resuming is that something.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    unawaited(_inboxChanges.cancel());
    _lifecycle.dispose();
    super.dispose();
  }

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
          icon: Icon(Icons.collections_bookmark_outlined),
          label: Text('Scenarios'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.science_outlined),
          label: Text('Sandbox'),
        ),
      ],
    ),
    // top: false because the AppBar already sits below the status bar; the
    // insets that matter here are the bottom gesture bar — which the Sandbox's
    // pinned SendFooter would otherwise sit underneath — and the side cutouts in
    // landscape. Applied once around the IndexedStack rather than in each
    // destination, so a new page cannot forget it.
    body: SafeArea(
      top: false,
      child: IndexedStack(
        index: _destination,
        children: [
          InboxView(inbox: widget.inbox),
          ScenariosView(
            controller: widget.sandbox,
            onScenarioSelected: _openSandbox,
          ),
          SandboxView(controller: widget.sandbox),
        ],
      ),
    ),
  );

  /// Applies the drawer's choice and gets the drawer out of the way, which
  /// `NavigationDrawer` does not do on its own.
  void _select(int index) {
    setState(() => _destination = index);
    Navigator.pop(context);
  }

  /// Switches to the Sandbox once a scenario has been applied from the
  /// Scenarios page. Unlike [_select], this is not a drawer choice, so there
  /// is no drawer open to pop.
  void _openSandbox() {
    setState(() => _destination = _sandboxDestination);
  }

  void _onResume() => unawaited(widget.inbox.drainPending());

  /// Acts on a notification tap once its message is known.
  ///
  /// Selecting the inbox happens as soon as a tap is outstanding: it is the
  /// fallback for an id that will never resolve — evicted by the cap, or rejected
  /// as malformed — and the right backdrop for the page about to be pushed.
  void _onInboxChanged(InboxState inbox) {
    if (!inbox.hasPendingOpen) {
      return;
    }

    if (_destination != _inboxDestination) {
      setState(() => _destination = _inboxDestination);
    }

    final message = inbox.pendingOpen;
    if (message == null) {
      return;
    }

    // Cleared before navigating, so a later event cannot push twice — including
    // the one this clear itself publishes, which arrives with no pending open
    // and is turned away by the guard above.
    widget.inbox.clearPendingOpen();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MessageDetailPage(message)),
      ),
    );
  }
}
