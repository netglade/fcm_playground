import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains/runs/entities/run_scheduler.dart';
import '../inbox/cubit/inbox_cubit.dart';
import '../inbox/cubit/inbox_state.dart';
import '../inbox/inbox_view.dart';
import '../inbox/message_detail_page.dart';
import '../runs/run_timeline_page.dart';
import '../runs/runs_view.dart';
import '../sandbox/sandbox_view.dart';
import '../scenarios/scenarios_view.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer's selection,
/// and one body per destination.
///
/// The destinations sit in an `IndexedStack` so all four keep their state — the
/// half-filled Sandbox form survives a look at the inbox or the gallery. Both
/// cubits come from `context`, which is what lets Scenarios and Sandbox share one
/// [SandboxCubit] across a tab switch. Runs reads its `RunScheduler` from
/// `context` too, provided above `App`'s shell rather than looked up here.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = ['Push inbox', 'Scenarios', 'Sandbox', 'Runs'];
  static const _inboxDestination = 0;
  static const _sandboxDestination = 2;
  // No `_runsDestination` constant yet: nothing in this file reads one, and an
  // unread private field is `unused_field`, fatal here. Task 15 adds it back
  // alongside the switch that actually reads it.

  late final AppLifecycleListener _lifecycle;

  int _destination = _inboxDestination;

  @override
  void initState() {
    super.initState();
    // A push that arrived while the app was merely backgrounded sits in the
    // pending key until something drains it, and resuming is that something.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<InboxCubit, InboxState>(
    listener: _onInboxChanged,
    child: Scaffold(
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
          NavigationDrawerDestination(
            icon: Icon(Icons.schedule_outlined),
            label: Text('Runs'),
          ),
        ],
      ),
      // top: false because the AppBar already sits below the status bar. Applied
      // once around the IndexedStack rather than in each destination, so a new
      // page cannot forget the bottom gesture bar the SendFooter sits above.
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _destination,
          children: [
            const InboxView(),
            ScenariosView(onScenarioSelected: _openSandbox),
            const SandboxView(),
            RunsView(
              scheduler: context.read<RunScheduler>(),
              onRunSelected: (runId) => _openRun(context, runId),
            ),
          ],
        ),
      ),
    ),
  );

  /// Applies the drawer's choice and gets the drawer out of the way, which
  /// `NavigationDrawer` does not do on its own.
  void _select(int index) {
    setState(() => _destination = index);
    Navigator.pop(context);
  }

  /// Unlike [_select], this is not a drawer choice, so there is no drawer to pop.
  void _openSandbox() {
    setState(() => _destination = _sandboxDestination);
  }

  void _onResume() => unawaited(context.read<InboxCubit>().drainPending());

  /// Pushes the timeline for [runId], reached only by tapping a run — never a
  /// drawer choice, so there is no destination index to set.
  void _openRun(BuildContext context, String runId) => unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunTimelinePage(
          scheduler: context.read<RunScheduler>(),
          runId: runId,
        ),
      ),
    ),
  );

  /// Acts on a notification tap once its message is known.
  ///
  /// Selecting the inbox happens as soon as a tap is outstanding: it is the
  /// fallback for an id that will never resolve — evicted by the cap, or rejected
  /// as malformed.
  void _onInboxChanged(BuildContext context, InboxState inbox) {
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
    // the one this clear itself publishes, which arrives with no pending open and
    // is turned away by the guard above.
    context.read<InboxCubit>().clearPendingOpen();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MessageDetailPage(message)),
      ),
    );
  }
}
