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
  late int selectedCount;

  void build() {
    controller = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => 'device-token',
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
    selectedCount = 0;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: controller,
            child: ScenariosView(onScenarioSelected: () => selectedCount++),
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
}
