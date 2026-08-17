import 'package:fcm_app/domains/runs/entities/active_run_store.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/scenarios/scenarios_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../fakes/fake_notification_sender.dart';
import '../../fakes/fake_run_scheduler.dart';
import '../../fakes/in_memory_active_run_store.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late SandboxCubit controller;
  late FakeRunScheduler runs;
  late InMemoryActiveRunStore active;
  late int selectedCount;

  void build({String? token = 'device-token'}) {
    runs = FakeRunScheduler();
    active = InMemoryActiveRunStore();
    controller = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => token,
      startRun: StartRun(scheduler: runs, active: active),
    );
    selectedCount = 0;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RunScheduler>.value(value: runs),
            RepositoryProvider<ActiveRunStore>.value(value: active),
            RepositoryProvider<StartRun>.value(
              value: StartRun(scheduler: runs, active: active),
            ),
          ],
          child: Scaffold(
            body: BlocProvider.value(
              value: controller,
              child: ScenariosView(onScenarioSelected: () => selectedCount++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  final first = scenarioGallery.first;

  tearDown(() => controller.close());

  testWidgets('lists every group', (tester) async {
    build();

    await pump(tester);

    for (final group in scenarioGallery.map((s) => s.group).toSet()) {
      expect(find.text(group), findsOne, reason: group);
    }
  });

  testWidgets("shows the first group's scenarios with their descriptions", (
    tester,
  ) async {
    build();

    await pump(tester);

    expect(find.text(first.title), findsOne);
    expect(find.text(first.description), findsOne);
  });

  testWidgets('shows an expectation when the scenario has one', (tester) async {
    build();

    await pump(tester);

    final withExpectation = scenarioGallery.firstWhere(
      (scenario) =>
          scenario.group == first.group && scenario.expectation != null,
    );
    expect(find.text(withExpectation.expectation!), findsOne);
  });

  testWidgets('flags the rows that cannot be demonstrated yet', (tester) async {
    // Every scenario in group A works, so a chip visible there would say nothing.
    // Group D's first row is the nearest one that should carry it.
    build();
    await pump(tester);
    expect(
      scenarioGallery
          .where((s) => s.group == first.group)
          .every((s) => s.isSupported),
      isTrue,
      reason: 'the assertion below assumes group A is entirely supported',
    );
    expect(find.text('needs work'), findsNothing);

    final needy = scenarioGallery.firstWhere(
      (s) => s.id == 'd1_importance_high',
    );
    await scrollIntoView(tester, find.text(needy.group));
    await tester.tap(find.text(needy.group));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.text(needy.title));

    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, needy.title),
        matching: find.text('needs work'),
      ),
      findsOne,
    );
  });

  testWidgets('applies the tapped scenario to the controller', (tester) async {
    build();
    await pump(tester);
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'a2_data_only');

    // Reaching a scenario below the first is a scroll within the gallery's own
    // page, unrelated to the Sandbox-page fold this change fixed.
    await scrollIntoView(tester, find.text(dataOnly.title));
    await tester.tap(find.text(dataOnly.title));
    await tester.pumpAndSettle();

    expect(controller.state.selectedScenario?.id, dataOnly.id);
  });

  testWidgets('calls onScenarioSelected once applyScenario has run', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();

    expect(selectedCount, 1);
    expect(controller.state.selectedScenario?.id, first.id);
  });

  group('choosing a batch', () {
    Future<void> startSelecting(WidgetTester tester) async {
      await tester.tap(find.text('Select for a batch'));
      await tester.pump();
    }

    Future<void> tick(WidgetTester tester, String id) async {
      final tile = find.byKey(Key('scenario-$id'));
      await scrollIntoView(tester, tile);
      await tester.tap(tile);
      await tester.pump();
    }

    testWidgets('offers a selection mode, with nothing selected', (
      tester,
    ) async {
      build();
      await pump(tester);

      expect(find.text('Select for a batch'), findsOne);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('shows a checkbox per scenario once selecting', (tester) async {
      build();
      await pump(tester);

      await startSelecting(tester);

      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('a tap ticks the box instead of loading the scenario', (
      tester,
    ) async {
      build();
      await pump(tester);
      await startSelecting(tester);
      // SandboxCubit's constructor already applies the catalogue's first
      // scenario, so the state to compare against is whatever it was before the
      // tick rather than a hardcoded id. That id must also differ from the one
      // ticked below — a1_notification_only would not, since it is that same
      // default — or a wrongly-applied scenario could not move it and this
      // assertion could never fail.
      final beforeTick = controller.state.selectedScenario?.id;

      await tick(tester, 'a3_hybrid');

      expect(find.text('1 selected'), findsOne);
      // Neither the Sandbox handoff nor the form ran, which is what a tap does
      // outside selection mode.
      expect(selectedCount, 0);
      expect(controller.state.selectedScenario?.id, beforeTick);
    });

    testWidgets('schedules every ticked scenario as one run', (tester) async {
      build();
      await pump(tester);
      await startSelecting(tester);
      await tick(tester, 'a1_notification_only');
      await tick(tester, 'a3_hybrid');

      await tester.tap(find.text('Schedule…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      final request = runs.scheduled.single;
      expect(request.items.map((i) => i.scenarioId), [
        'a1_notification_only',
        'a3_hybrid',
      ]);
      expect(request.items.first.target, const TokenTarget('device-token'));
    });

    testWidgets('orders the batch by the catalogue, not by tap order', (
      tester,
    ) async {
      build();
      await pump(tester);
      await startSelecting(tester);
      await tick(tester, 'a3_hybrid');
      await tick(tester, 'a1_notification_only');

      await tester.tap(find.text('Schedule…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(runs.scheduled.single.items.map((i) => i.scenarioId), [
        'a1_notification_only',
        'a3_hybrid',
      ]);
    });

    testWidgets('clears the selection and leaves the mode', (tester) async {
      build();
      await pump(tester);
      await startSelecting(tester);
      await tick(tester, 'a1_notification_only');

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Select for a batch'), findsOne);
    });

    testWidgets('says why it cannot schedule with no token yet', (
      tester,
    ) async {
      build(token: null);
      await pump(tester);
      await startSelecting(tester);
      await tick(tester, 'a1_notification_only');

      await tester.tap(find.text('Schedule…'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No registration token'), findsOne);
      expect(runs.scheduled, isEmpty);
    });

    testWidgets(
      'schedules a batch of only targeted scenarios with no token at all',
      (tester) async {
        // j1_topic names its own audience (a topic), so it needs no device
        // token — this is the positive case the refusal's narrower condition
        // (`token == null && scenarios.any((s) => s.target == null)`) exists
        // for, and a regression to plain `token == null` would refuse it.
        build(token: null);
        await pump(tester);
        await startSelecting(tester);
        // Group J starts collapsed — only the first group opens on arrival —
        // so its scenarios are not in the tree until the group is expanded.
        await scrollIntoView(tester, find.text('J — Targeting'));
        await tester.tap(find.text('J — Targeting'));
        await tester.pumpAndSettle();
        await tick(tester, 'j1_topic');

        await tester.tap(find.text('Schedule…'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Schedule'));
        await tester.pumpAndSettle();

        expect(runs.scheduled, hasLength(1));
        expect(find.textContaining('No registration token'), findsNothing);
      },
    );
  });
}
