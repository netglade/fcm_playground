import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/scenarios_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

void main() {
  late SandboxController controller;
  late int selectedCount;

  void build() {
    controller = SandboxController(
      sender: FakeNotificationSender(),
      token: () => 'device-token',
    );
    selectedCount = 0;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScenariosView(
            controller: controller,
            onScenarioSelected: () => selectedCount++,
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

  tearDown(() => controller.dispose());

  testWidgets('lists every group', (tester) async {
    build();

    await pump(tester);

    for (final group in scenarioGallery.map((s) => s.group).toSet()) {
      expect(find.text(group), findsOne, reason: group);
    }
  });

  testWidgets("shows the first group's scenarios and their tags", (
    tester,
  ) async {
    build();

    await pump(tester);

    expect(find.text(first.title), findsOne);
    for (final tag in first.tags) {
      expect(find.text(tag), findsAtLeast(1));
    }
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

  testWidgets('applies the tapped scenario to the controller', (tester) async {
    build();
    await pump(tester);
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'data_only');

    // Reaching a later group is a scroll within the gallery's own page,
    // which is unrelated to the bug this change fixes: that was the editor
    // on the *Sandbox* page sitting below the fold with nothing above it.
    await scrollIntoView(tester, find.text(dataOnly.group));
    await tester.tap(find.text(dataOnly.group));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.text(dataOnly.title));
    await tester.tap(find.text(dataOnly.title));
    await tester.pumpAndSettle();

    expect(controller.selectedScenario?.id, dataOnly.id);
  });

  testWidgets('calls onScenarioSelected once applyScenario has run', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();

    expect(selectedCount, 1);
    expect(controller.selectedScenario?.id, first.id);
  });
}
