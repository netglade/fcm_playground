import 'dart:async';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domains/runs/entities/active_run_store.dart';
import '../../domains/runs/entities/run_scheduler.dart';
import '../../domains/runs/entities/run_scheduler_exception.dart';
import '../../domains/telemetry/entities/telemetry_reader.dart';
import '../inbox/cubit/inbox_cubit.dart';
import '../inbox/cubit/inbox_state.dart';
import '../inbox/inbox_view.dart';
import '../inbox/message_detail_page.dart';
import '../runs/run_timeline_page.dart';
import '../runs/runs_view.dart';
import '../sandbox/sandbox_view.dart';
import '../scenarios/scenarios_view.dart';
import '../telemetry/telemetry_view.dart';
import 'deep_link_destination.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer's selection,
/// and one body per destination.
///
/// The destinations sit in an `IndexedStack` so all five keep their state — the
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
  static const _titles = [
    'Push inbox',
    'Scenarios',
    'Sandbox',
    'Runs',
    'Telemetry',
  ];
  late final AppLifecycleListener _lifecycle;

  int _destination = inboxDestination;

  /// Bumped every time Runs is chosen from the drawer, and used as [RunsView]'s
  /// key below.
  ///
  /// `IndexedStack` builds every destination up front and keeps them alive, so
  /// without this a page-local `RunsCubit` built once at launch would call
  /// `load()` exactly once and never again — schedule a run, open Runs, and the
  /// page would still say nothing has been scheduled. Changing the key forces
  /// Flutter to discard that element and build a fresh one, whose `BlocProvider`
  /// runs `create` — and `load()` — again. `RunsView` stays exactly as
  /// page-local as its own doc already claims: this only changes *when* a new
  /// page begins, not who owns it.
  int _runsVisits = 0;

  /// Bumped every time Telemetry is chosen from the drawer, and used as
  /// [TelemetryView]'s key below, for the reason [_runsVisits] spells out: an
  /// `IndexedStack` keeps every destination alive, so a page-local cubit built once
  /// at launch would `load()` once and never again.
  int _telemetryVisits = 0;

  @override
  void initState() {
    super.initState();
    // A push that arrived while the app was merely backgrounded sits in the
    // pending key until something drains it, and resuming is that something.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // After the first frame, because this pushes a route and there is no navigator
    // to push onto until the tree is built.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_openAwaitedRun()),
    );
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
          NavigationDrawerDestination(
            icon: Icon(Icons.analytics_outlined),
            label: Text('Telemetry'),
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
              key: ValueKey(_runsVisits),
              scheduler: context.read<RunScheduler>(),
              onRunSelected: (runId) => _openRun(context, runId),
            ),
            TelemetryView(
              key: ValueKey(_telemetryVisits),
              reader: context.read<TelemetryReader>(),
            ),
          ],
        ),
      ),
    ),
  );

  /// Applies the drawer's choice and gets the drawer out of the way, which
  /// `NavigationDrawer` does not do on its own.
  void _select(int index) {
    setState(() {
      _destination = index;
      if (index == runsDestination) {
        _runsVisits++;
      }
      if (index == telemetryDestination) {
        _telemetryVisits++;
      }
    });
    Navigator.pop(context);
  }

  /// Unlike [_select], this is not a drawer choice, so there is no drawer to pop.
  void _openSandbox() {
    setState(() => _destination = sandboxDestination);
  }

  void _onResume() => unawaited(context.read<InboxCubit>().drainPending());

  /// Opens the timeline of the run the user was waiting on, if it has finished.
  ///
  /// This is the far end of the countdown: it told the user to swipe the app away,
  /// so by the time there is a result there is no cubit left holding it — only the
  /// id in [ActiveRunStore].
  ///
  /// A run still outstanding is left alone, and so is the stored id when the API
  /// cannot be reached: losing it would lose the only pointer back to the result.
  /// The timing works out for the killed case in particular — `received_bg` is
  /// buffered by the background isolate and flushed at the next launch, which is
  /// this moment.
  ///
  /// A notification tap outstanding at the same launch wins over this: the user
  /// already asked to go somewhere, and this must not push a page on top of that
  /// unasked for. See the check before the push below.
  Future<void> _openAwaitedRun() async {
    final active = context.read<ActiveRunStore>();
    final runId = await active.activeRunId();
    if (runId == null || !mounted) {
      return;
    }

    final scheduler = context.read<RunScheduler>();
    final ScheduledRun run;
    try {
      run = await scheduler.fetch(runId);
    } on RunSchedulerException {
      return;
    }
    if (run.items.any((item) => item.state.isOutstanding) || !mounted) {
      return;
    }

    await active.clear();
    if (!mounted) {
      return;
    }

    // The user's own navigation wins. `b3_killed` is exactly this: the push
    // arrives while the app is dead, the user taps it, the app starts — and by
    // the time this method's two awaits are done, `_onInboxChanged` has already
    // pushed `MessageDetailPage` for that tap. Pushing the timeline on top of it
    // would ambush the user with a page they did not ask for. The id is cleared
    // above regardless: it existed to get the user back to the result, and
    // tapping the notification did that. The timeline stays one tap away on the
    // Runs page — deferring this push to the next launch would just move the
    // ambush to a later start rather than remove it.
    if (context.read<InboxCubit>().state.hasPendingOpen) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunTimelinePage(scheduler: scheduler, runId: runId),
      ),
    );
  }

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
  /// as malformed. A link that names a destination of its own overrides that,
  /// because passing through the inbox on the way would show the user a screen
  /// they did not ask for.
  void _onInboxChanged(BuildContext context, InboxState inbox) {
    if (!inbox.hasPendingOpen) {
      return;
    }

    final message = inbox.pendingOpen;
    final destination = message == null
        ? null
        : deepLinkDestination(message.data[deepLinkKey]);

    if (destination is! ShellDestination && _destination != inboxDestination) {
      setState(() => _destination = inboxDestination);
    }

    if (message == null) {
      return;
    }

    // Cleared before navigating, so a later event cannot push twice — including
    // the one this clear itself publishes, which arrives with no pending open and
    // is turned away by the guard above.
    context.read<InboxCubit>().clearPendingOpen();

    switch (destination) {
      case ShellDestination(:final index):
        setState(() => _destination = index);
      case RunTimelineDestination(:final runId):
        _openRun(context, runId);
      case null:
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MessageDetailPage(
                message,
                pressedAction: inbox.pressedActions[message.id],
              ),
            ),
          ),
        );
    }
  }
}
