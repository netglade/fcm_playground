import 'package:fcm_app/sandbox/sandbox_cubit.dart';
import 'package:fcm_app/ui/send_target_field.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../fake_notification_sender.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late SandboxCubit controller;

  setUp(() {
    controller = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => 'device-token',
    );
  });

  tearDown(() => controller.close());

  Scenario scenario(String id) =>
      scenarioGallery.firstWhere((scenario) => scenario.id == id);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SendTargetField(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // A closed DropdownButton keeps every item in the tree but hides the ones it
  // is not showing, and the default finders skip those — so `findsOne` on a
  // kind's label is a statement about what is *selected*, not merely offered.
  // Verified: with nothing chosen, only the hint-selected entry is found.

  testWidgets('defaults to this device, with nothing to type', (tester) async {
    await pump(tester);

    expect(find.text('This device'), findsOne);
    expect(find.text('Topic'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(controller.state.target, isNull);
  });

  testWidgets('choosing a topic reveals a field and sets the target', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topic').last);
    await tester.pumpAndSettle();

    // Blank on purpose: the kind is chosen before its value is known, and the
    // controller has to refuse to send that rather than pick an audience.
    expect(controller.state.target, const TopicTarget(''));
    expect(find.byType(TextField), findsOne);
    expect(controller.sendBlockedReason, isNotNull);

    await tester.enterText(find.byType(TextField), 'news');
    await tester.pumpAndSettle();

    expect(controller.state.target, const TopicTarget('news'));
    expect(controller.sendBlockedReason, isNull);
  });

  testWidgets('switching kind drops the previous value', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topic').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'news');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condition').last);
    await tester.pumpAndSettle();

    // A topic name left behind in a condition box would be read as an
    // expression and sent to nobody.
    expect(controller.state.target, const ConditionTarget(''));
    expect(find.widgetWithText(TextField, 'news'), findsNothing);
  });

  testWidgets('all devices needs no text and warns it is unsupported', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All devices').last);
    await tester.pumpAndSettle();

    expect(controller.state.target, const AllDevicesTarget());
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('registry'), findsOne);
  });

  testWidgets('a scenario with a topic preselects it', (tester) async {
    controller.applyScenario(scenario('j1_topic'));

    await pump(tester);

    expect(find.text('Topic'), findsOne);
    expect(find.text('This device'), findsNothing);
    expect(find.widgetWithText(TextField, 'news'), findsOne);
  });

  testWidgets('applying an ordinary scenario resets to this device', (
    tester,
  ) async {
    controller.applyScenario(scenario('j1_topic'));
    // Without this, the reset below would pass on a controller whose
    // applyScenario never touched the target at all.
    expect(controller.state.target, const TopicTarget('news'));

    controller.applyScenario(scenario('a1_notification_only'));

    await pump(tester);

    expect(controller.state.target, isNull);
    expect(find.text('This device'), findsOne);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a scenario applied while on screen takes over the field', (
    tester,
  ) async {
    // The app's real path: the Sandbox page stays mounted in the shell's
    // IndexedStack while the gallery applies a scenario, so the selector has to
    // follow the controller rather than only read it once when it was built.
    await pump(tester);

    controller.applyScenario(scenario('j1_topic'));
    await tester.pumpAndSettle();

    expect(find.text('Topic'), findsOne);
    expect(find.widgetWithText(TextField, 'news'), findsOne);

    controller.applyScenario(scenario('a1_notification_only'));
    await tester.pumpAndSettle();

    expect(find.text('This device'), findsOne);
    expect(find.byType(TextField), findsNothing);
  });
}
