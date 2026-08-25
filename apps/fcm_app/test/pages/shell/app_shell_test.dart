import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/domains/runs/entities/active_run_store.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler_exception.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/settings/entities/locale_store.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_reader.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_app/pages/inbox/cubit/inbox_cubit.dart';
import 'package:fcm_app/pages/inbox/message_detail_page.dart';
import 'package:fcm_app/pages/runs/run_timeline_page.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/shell/app_shell.dart';
import 'package:fcm_app/pages/shell/deep_link_destination.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_locale_store.dart';
import '../../fakes/fake_notification_sender.dart';
import '../../fakes/fake_push_payload_store.dart';
import '../../fakes/fake_push_source.dart';
import '../../fakes/fake_run_scheduler.dart';
import '../../fakes/fake_telemetry_reader.dart';
import '../../fakes/in_memory_active_run_store.dart';
import '../../fakes/recording_navigator_observer.dart';

Map<String, Object?> payload({String id = 'msg-1', String? deepLink}) => {
  'id': id,
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-11T09:30:00Z',
  'deep_link': ?deepLink,
};

void main() {
  setUpAll(GladeForms.initialize);

  late FakePushSource source;
  late PushRepository repository;
  late InboxCubit inbox;
  late SandboxCubit sandbox;

  // The shell under providers of the test's own, rather than `App`: that
  // widget's `BlocProvider`s pull their collaborators out of `getIt`, which no test
  // here configures.
  //
  // Everything but the source is built here rather than in `setUp`, because of a
  // zone. A cubit's state stream schedules delivery with
  // `Zone.current.scheduleMicrotask`, so a cubit built in `setUp` subscribes in the
  // outer test zone — which `testWidgets` does not drive, leaving the microtask
  // somewhere `pumpAndSettle` never flushes. Measured: the notification-tap tests
  // below go silent.
  //
  // Named `pumpApp` and built as a full `MaterialApp` of its own rather than routed
  // through the shared `pump_app.dart` helper of the same name: this closure needs
  // `navigatorObservers`, which is a `MaterialApp` constructor argument the helper's
  // `child` slot cannot reach. `TranslationProvider` still wraps it directly, for the
  // same reason the helper carries one: `AppShell` reads `context.t` for its
  // language-switcher tooltip.
  Future<void> pumpApp(
    WidgetTester tester, {
    FakePushPayloadStore? store,
    NavigatorObserver? observer,
    ActiveRunStore? active,
    FakeRunScheduler? scheduler,
    TelemetryReader? reader,
    // Set before the first frame, so it is already outstanding by the time
    // `_openAwaitedRun`'s post-frame callback checks for one — unlike the other
    // notification-tap tests below, which fire `requestOpen` after settling to
    // exercise `_onInboxChanged` reacting to a later state change instead.
    String? pendingTapId,
  }) async {
    repository = PushRepository(source, store: store ?? FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    if (pendingTapId != null) {
      inbox.requestOpen(pendingTapId, OpenedFrom.background);
    }
    sandbox = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => inbox.state.token,
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          navigatorObservers: [?observer],
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RunScheduler>.value(
                value: scheduler ?? FakeRunScheduler(),
              ),
              RepositoryProvider<ActiveRunStore>.value(
                value: active ?? InMemoryActiveRunStore(),
              ),
              RepositoryProvider<TelemetryReader>.value(
                value: reader ?? FakeTelemetryReader(),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: inbox),
                BlocProvider.value(value: sandbox),
              ],
              child: const AppShell(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }

  // The outermost stack is the shell's: a closed `DropdownButton` builds an
  // `IndexedStack` of its items too, and finders walk the tree from the root.
  int? selectedDestination(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index;

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    source = FakePushSource();
    // Pinned rather than inherited: an assertion on English copy elsewhere in this
    // file must not start failing because the host is Czech. The one test below that
    // switches languages restores this in its own `addTearDown`.
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await sandbox.close();
    await inbox.close();
    repository.dispose();
    await source.dispose();
  });

  testWidgets('opens on the inbox', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
    expect(selectedDestination(tester), 0);
  });

  testWidgets('offers all five destinations in the drawer', (tester) async {
    await pumpApp(tester);

    await openDrawer(tester);

    expect(find.text('Inbox'), findsOne);
    expect(find.text('Scenarios'), findsOne);
    expect(find.text('Sandbox'), findsOne);
    expect(find.text('Runs'), findsOne);
    expect(find.text('Telemetry'), findsOne);
  });

  testWidgets('switches to the scenarios page and retitles the bar', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Scenarios'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 1);
    expect(find.widgetWithText(AppBar, 'Scenarios'), findsOne);
  });

  testWidgets('switches to the sandbox and retitles the bar', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 2);
    expect(find.widgetWithText(AppBar, 'Sandbox'), findsOne);
  });

  testWidgets('closes the drawer once a destination is chosen', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('switches back to the inbox', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);
    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 0);
    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
  });

  testWidgets(
    'reloads the Runs page each time it is chosen, not just at launch',
    (tester) async {
      // Growable, and held onto by the test: `FakeRunScheduler.list` answers
      // whatever is in here at the moment it is called, so mutating it between
      // two visits stands in for a run appearing on the server in between —
      // exactly what happens after scheduling one from another tab.
      final summaries = <RunSummary>[];
      await pumpApp(tester, scheduler: FakeRunScheduler(summaries: summaries));

      await openDrawer(tester);
      await tester.tap(find.text('Runs'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing scheduled yet'), findsOneWidget);

      summaries.add(
        RunSummary(
          runId: 'run-1',
          createdAt: FakeRunScheduler.createdAt,
          itemCount: 1,
          states: const {RunItemState.pending: 1},
          nextDueAt: FakeRunScheduler.createdAt.add(
            const Duration(seconds: 30),
          ),
        ),
      );

      await openDrawer(tester);
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      await openDrawer(tester);
      await tester.tap(find.text('Runs'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing scheduled yet'), findsNothing);
      expect(find.byKey(const Key('run-run-1')), findsOneWidget);
    },
  );

  testWidgets('opens Telemetry from the drawer', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);
    await tester.tap(find.text('Telemetry'));
    await tester.pumpAndSettle();

    // The title comes from the shell, so this is what proves the destination is
    // selected rather than merely present in the drawer.
    expect(find.widgetWithText(AppBar, 'Telemetry'), findsOneWidget);
  });

  testWidgets(
    'reloads the Telemetry page each time it is chosen, not just at launch',
    (tester) async {
      // Growable, and held onto by the test, mirroring the Runs test above:
      // `FakeTelemetryReader` answers the same list instance it was built with, so
      // mutating it between two visits stands in for an event arriving on the
      // server in between.
      final events = <TelemetryEvent>[];
      await pumpApp(tester, reader: FakeTelemetryReader(events: events));

      await openDrawer(tester);
      await tester.tap(find.text('Telemetry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing recorded yet'), findsOneWidget);

      events.add(
        TelemetryEvent(
          traceId: 't1',
          type: TelemetryEventType.queued,
          at: DateTime.utc(2026, 8, 18, 9, 30),
          deviceId: '',
          scenarioId: 'a1_notification_only',
        ),
      );

      await openDrawer(tester);
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      await openDrawer(tester);
      await tester.tap(find.text('Telemetry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing recorded yet'), findsNothing);
      expect(find.textContaining('t1'), findsWidgets);
    },
  );

  testWidgets('tapping a scenario switches to the sandbox with it loaded', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);
    await tester.tap(find.text('Scenarios'));
    await tester.pumpAndSettle();
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'a2_data_only');

    // Reaching a scenario below the first is a scroll within the gallery's own
    // page, unrelated to the Sandbox-page fold this change fixed.
    await scrollIntoView(tester, find.text(dataOnly.title));
    await tester.tap(find.text(dataOnly.title));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 2);
    expect(find.widgetWithText(AppBar, 'Sandbox'), findsOne);
    expect(sandbox.state.selectedScenario?.id, dataOnly.id);
    expect(sandbox.form.data.value, dataOnly.payloadTemplate['data']);
  });

  Future<void> openSandbox(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the detail page for a tapped notification', (
    tester,
  ) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(inbox.state.hasPendingOpen, isFalse);
  });

  testWidgets('a link naming a destination switches to it', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped', deepLink: '/telemetry'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), telemetryDestination);
    expect(
      find.byType(MessageDetailPage),
      findsNothing,
      reason:
          'the user asked to go to Telemetry, and pushing the detail page over '
          'it would be a screen they did not ask for',
    );
  });

  testWidgets('a /runs/<id> link pushes that timeline', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped', deepLink: '/runs/run-7'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();

    expect(find.byType(RunTimelinePage), findsOne);
    expect(find.byType(MessageDetailPage), findsNothing);
  });

  testWidgets('an unrecognised link opens the detail page', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped', deepLink: '/builds/128'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();

    expect(
      find.byType(MessageDetailPage),
      findsOne,
      reason:
          'the detail page lists deep_link among its data rows, so an app with '
          'no such screen still shows the user what the notification asked for',
    );
  });

  testWidgets('leaves the sandbox for the inbox when a tap arrives', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSandbox(tester);

    inbox.requestOpen('never-seen', OpenedFrom.background);
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 0);
    expect(find.byType(MessageDetailPage), findsNothing);
  });

  testWidgets('opens the page once the message catches up', (tester) async {
    await pumpApp(tester);

    inbox.requestOpen('late', OpenedFrom.background);
    await tester.pumpAndSettle();
    expect(find.byType(MessageDetailPage), findsNothing);
    source.emit(payload(id: 'late'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('does not open the page twice for one tap', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();
    source.emit(payload(id: 'unrelated'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('clears the pending open before it navigates', (tester) async {
    // The ordering, observed at the only moment it is observable: by the time
    // `pumpAndSettle` returns, both orderings have cleared and navigated exactly
    // once. A `NavigatorObserver`'s `didPush` runs *inside* the push, so this is
    // where clearing first is distinguishable — and it matters because the clear
    // publishes, so a watcher woken between the two would route the tap twice.
    final pendingAtPush = <bool>[];
    await pumpApp(
      tester,
      observer: RecordingNavigatorObserver(
        (_) => pendingAtPush.add(inbox.state.hasPendingOpen),
      ),
    );
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped', OpenedFrom.background);
    await tester.pumpAndSettle();

    // The last push is the detail route — the one before it is the shell itself,
    // pushed before any tap existed.
    expect(find.byType(MessageDetailPage), findsOne);
    expect(pendingAtPush.last, isFalse);
  });

  testWidgets('drains pending payloads when the app resumes', (tester) async {
    // The store is handed in because this test keeps hold of the one it puts a
    // pending payload into. The zone note above applies here too.
    final store = FakePushPayloadStore();
    await pumpApp(tester, store: store);
    store.pending.add(payload(id: 'while-away'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(inbox.state.messages.single.id, 'while-away');
  });

  group('coming back to a scheduled run', () {
    ScheduledRun runWith(RunItemState state) => ScheduledRun(
      id: 'run-1',
      createdAt: FakeRunScheduler.createdAt,
      items: [
        ScheduledRunItem(
          index: 0,
          request: SendMessageRequest(
            target: const TokenTarget('device-token'),
            message: const FcmMessage(),
            scenarioId: 'b3_killed',
          ),
          dueAt: FakeRunScheduler.createdAt.add(const Duration(seconds: 30)),
          state: state,
        ),
      ],
    );

    testWidgets('opens the timeline of a run that has finished', (
      tester,
    ) async {
      final active = InMemoryActiveRunStore();
      await active.setActiveRunId('run-1');
      final scheduler = FakeRunScheduler()
        ..runs['run-1'] = runWith(RunItemState.sent);

      await pumpApp(tester, active: active, scheduler: scheduler);
      await tester.pumpAndSettle();

      expect(find.byType(RunTimelinePage), findsOneWidget);
      // Cleared, so a second launch does not reopen it.
      expect(await active.activeRunId(), isNull);
    });

    testWidgets('leaves a run that is still outstanding alone', (tester) async {
      final active = InMemoryActiveRunStore();
      await active.setActiveRunId('run-1');
      final scheduler = FakeRunScheduler()
        ..runs['run-1'] = runWith(RunItemState.pending);

      await pumpApp(tester, active: active, scheduler: scheduler);
      await tester.pumpAndSettle();

      expect(find.byType(RunTimelinePage), findsNothing);
      expect(await active.activeRunId(), 'run-1');
    });

    testWidgets('leaves a dispatching run alone too, not just a pending one', (
      tester,
    ) async {
      final active = InMemoryActiveRunStore();
      await active.setActiveRunId('run-1');
      final scheduler = FakeRunScheduler()
        ..runs['run-1'] = runWith(RunItemState.dispatching);

      await pumpApp(tester, active: active, scheduler: scheduler);
      await tester.pumpAndSettle();

      expect(find.byType(RunTimelinePage), findsNothing);
      expect(await active.activeRunId(), 'run-1');
    });

    testWidgets(
      "defers to the user's own navigation: an outstanding notification tap "
      'wins over reopening a finished run',
      (tester) async {
        final active = InMemoryActiveRunStore();
        await active.setActiveRunId('run-1');
        final scheduler = FakeRunScheduler()
          ..runs['run-1'] = runWith(RunItemState.sent);

        await pumpApp(
          tester,
          active: active,
          scheduler: scheduler,
          pendingTapId: 'tapped',
        );
        await tester.pumpAndSettle();

        expect(find.byType(RunTimelinePage), findsNothing);
        // Still cleared: the id did its job the moment the user tapped their way
        // back in, even though this launch shows them the notification instead of
        // the timeline.
        expect(await active.activeRunId(), isNull);
      },
    );

    testWidgets('opens nothing when no run is awaited', (tester) async {
      await pumpApp(
        tester,
        active: InMemoryActiveRunStore(),
        scheduler: FakeRunScheduler(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RunTimelinePage), findsNothing);
    });

    testWidgets('keeps the id when the API cannot be reached', (tester) async {
      final active = InMemoryActiveRunStore();
      await active.setActiveRunId('run-1');

      await pumpApp(
        tester,
        active: active,
        scheduler: FakeRunScheduler(
          failure: const RunSchedulerException('Could not reach the API'),
        ),
      );
      await tester.pumpAndSettle();

      // Not cleared: the run is still out there, and the next launch should try
      // again rather than lose it.
      expect(await active.activeRunId(), 'run-1');
    });
  });

  testWidgets('the language menu switches the whole app', (tester) async {
    // The end-to-end proof that codegen, the provider and the store meet: an
    // English drawer label becomes a Czech one without touching the device.
    SharedPreferences.setMockInitialValues({});
    // The switcher writes through the locator, so the locator has to have one.
    // Without this the tap throws a StateError about an unregistered LocaleStore,
    // long before reaching the assertion below.
    getIt.registerSingleton<LocaleStore>(FakeLocaleStore());
    addTearDown(() => getIt.unregister<LocaleStore>());
    LocaleSettings.setLocaleSync(AppLocale.en);
    // LocaleSettings is global process state, and this test deliberately leaves it
    // on Czech. Restoring it is not tidiness: without it the next English-asserting
    // test the runner reaches fails, and the failure looks unrelated to this one.
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    await tester.pumpWidget(
      TranslationProvider(child: const MaterialApp(home: AppShell())),
    );

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Čeština').last);
    await tester.pumpAndSettle();

    expect(find.text('Doručené'), findsWidgets);
    expect(find.text('Inbox'), findsNothing);
  });
}
