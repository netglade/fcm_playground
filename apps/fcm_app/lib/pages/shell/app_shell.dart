import 'dart:async';

import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/domains.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/pages.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer, and one
/// body per destination.
///
/// The destinations sit in an `IndexedStack` so all six keep their state — a
/// half-filled Sandbox form survives a look at the inbox. Cubits come from
/// `context`, which is what lets Scenarios and Sandbox share one
/// [SandboxCubit].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// One AppBar title per destination, ordered like the `IndexedStack` and the
  /// drawer.
  ///
  /// A method, not a `const` list: a `const` cannot read [Translations], and the
  /// title must follow the language switch.
  List<String> _titlesFor(Translations t) => [
    t.shell.title.inbox,
    t.shell.title.scenarios,
    t.shell.title.sandbox,
    t.shell.title.runs,
    t.shell.title.telemetry,
    t.channels.title,
  ];
  late final AppLifecycleListener _lifecycle;

  int _destination = inboxDestination;

  /// Bumped every time Runs is chosen from the drawer, and used as [RunsView]'s
  /// key below.
  ///
  /// `IndexedStack` keeps every destination alive, so a page-local `RunsCubit`
  /// would `load()` once at launch and never again — schedule a run, open Runs,
  /// and the page still says nothing is scheduled. A new key discards the element
  /// so its `BlocProvider` builds and loads afresh.
  int _runsVisits = 0;

  /// Bumped every time Telemetry is chosen from the drawer, and used as
  /// [TelemetryView]'s key below, for the reason [_runsVisits] spells out: an
  /// `IndexedStack` keeps every destination alive, so a page-local cubit built once
  /// at launch would `load()` once and never again.
  int _telemetryVisits = 0;

  /// Bumped every time Channels is chosen, keying the `BlocProvider` around
  /// [ChannelsView], for the reason [_runsVisits] gives.
  ///
  /// The provider lives here rather than in the view, because [ChannelsView]
  /// reads its cubit from `context` like `SandboxView` does. Android channel
  /// state changes whenever the user edits it in system settings, so a stale read
  /// would be misleading rather than merely old.
  int _channelsVisits = 0;

  @override
  void initState() {
    super.initState();
    // A push arriving while merely backgrounded sits in the pending key until
    // something drains it; resuming is that something.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // After the first frame: this pushes a route, and there is no navigator
    // until the tree is built.
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
  Widget build(BuildContext context) {
    final t = context.t;

    return BlocListener<InboxCubit, InboxState>(
      listener: _onInboxChanged,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titlesFor(t)[_destination]),
          actions: [
            // Here rather than behind a settings page the app does not have.
            PopupMenuButton<AppLocale?>(
              icon: const Icon(Icons.translate),
              tooltip: t.language.tooltip,
              onSelected: (locale) async {
                // Persist, then switch: the switch rebuilds this widget, so a
                // write awaited after would race its own disposal.
                await getIt<LocaleStore>().write(locale);
                if (locale == null) {
                  LocaleSettings.useDeviceLocaleSync();
                } else {
                  LocaleSettings.setLocaleSync(locale);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: null, child: Text(t.language.system)),
                PopupMenuItem(
                  value: AppLocale.en,
                  child: Text(t.language.english),
                ),
                PopupMenuItem(
                  value: AppLocale.cs,
                  child: Text(t.language.czech),
                ),
              ],
            ),
          ],
        ),
        drawer: NavigationDrawer(
          selectedIndex: _destination,
          onDestinationSelected: _select,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 12),
              child: Text(t.app.title),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.inbox_outlined),
              label: Text(t.drawer.inbox),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: Text(t.drawer.scenarios),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.science_outlined),
              label: Text(t.drawer.sandbox),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.schedule_outlined),
              label: Text(t.drawer.runs),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.analytics_outlined),
              label: Text(t.drawer.telemetry),
            ),
            NavigationDrawerDestination(
              icon: const Icon(Icons.tune_outlined),
              label: Text(t.drawer.channels),
            ),
          ],
        ),
        // top: false — the AppBar is already below the status bar. Applied once
        // here, so a new page cannot forget the bottom gesture bar.
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
              BlocProvider(
                key: ValueKey(_channelsVisits),
                create: (_) =>
                    ChannelsCubit(context.read<NotificationChannelReader>())
                      ..load(),
                child: const ChannelsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      if (index == channelsDestination) {
        _channelsVisits++;
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
  /// The far end of the countdown: it told the user to swipe the app away, so by
  /// the time there is a result only the id in [ActiveRunStore] remains.
  ///
  /// An outstanding run is left alone, and so is the stored id when the API is
  /// unreachable — losing it loses the only pointer back to the result.
  ///
  /// An outstanding notification tap wins over this: the user already asked to go
  /// somewhere. See the check before the push below.
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

    // The user's own navigation wins — `b3_killed` is exactly this case, where
    // `_onInboxChanged` has already pushed `MessageDetailPage` by the time these
    // awaits finish. The id is cleared above regardless: it existed to get the
    // user back to the result, and the tap did that. The timeline stays one tap
    // away on Runs.
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
  /// The inbox is selected as soon as a tap is outstanding, as the fallback for an
  /// id that will never resolve — evicted by the cap, or malformed. Skipped when
  /// the link names its own destination, which the switch below is about to set
  /// anyway.
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

    // Cleared before navigating, so no later event pushes twice — including the
    // one this clear publishes, which the guard above turns away.
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
                reply: inbox.replies[message.id],
              ),
            ),
          ),
        );
    }
  }
}
