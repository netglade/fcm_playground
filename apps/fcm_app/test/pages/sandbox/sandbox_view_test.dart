import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/sandbox/entities/notification_send_exception.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/sandbox/sandbox_view.dart';
import 'package:fcm_app/pages/sandbox/widgets/manual_steps_block.dart';
import 'package:fcm_app/pages/sandbox/widgets/scenario_needs_banner.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_target_field.dart';
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

  late FakeNotificationSender sender;
  late SandboxCubit controller;

  void build({
    String? token = 'device-token',
    NotificationSendException? failure,
  }) {
    sender = FakeNotificationSender(failure: failure);
    controller = SandboxCubit(
      sender: sender,
      token: () => token,
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: controller,
            child: const SandboxView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => controller.close());

  testWidgets('shows the payload form without scrolling, on arrival', (
    tester,
  ) async {
    build();

    await pump(tester);

    // The regression test: found with no scroll helper of any kind.
    expect(find.text('message'), findsOne);
  });

  testWidgets('every block is reachable without a scroll helper', (
    tester,
  ) async {
    // Every top-level block must be on screen after nothing but a pump.
    build();

    await pump(tester);

    for (final block in const [
      'notification',
      'android',
      'apns',
      'webpush',
      'fcm_options',
    ]) {
      expect(find.text(block), findsOne);
    }
  });

  testWidgets('asks who to send to before anything else', (tester) async {
    // The one choice that cannot be corrected by reading the payload back, so it
    // heads the page rather than trailing 27 fields.
    build();

    await pump(tester);

    expect(find.byType(SendTargetField).hitTestable(), findsOne);
    expect(
      tester.getTopLeft(find.byType(SendTargetField)).dy,
      lessThan(tester.getTopLeft(find.byType(CheckboxListTile)).dy),
    );
  });

  testWidgets('a field edited on arrival reaches the model', (tester) async {
    // One tap, no scrolling.
    build();
    await pump(tester);

    await tester.tap(find.text('notification'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'title'),
      'Hello',
    );

    expect(controller.form.notification.title.value, 'Hello');
  });

  testWidgets('keeps Send on screen, whatever the form does', (tester) async {
    // As the last child of the scrolling list it sat below the fold and the lazy
    // `ListView` had not even built it. Pinned, it is hit-testable after one pump
    // and stays so as sections open.
    build();
    await pump(tester);

    expect(find.byType(FilledButton).hitTestable(), findsOne);

    await tester.tap(find.text('android'));
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton).hitTestable(), findsOne);
  });

  testWidgets('does not name the loaded scenario', (tester) async {
    // The gallery already names the scenario; repeating its title here only pushes
    // the payload further down. The caveat below it stays, being advice rather than
    // a label.
    build();

    await pump(tester);

    expect(find.text(controller.state.selectedScenario!.title), findsNothing);
  });

  testWidgets('disables Send while a field is invalid', (tester) async {
    build();
    await pump(tester);

    controller.form.android.ttl.updateValue('later');
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sends the edited payload', (tester) async {
    build();
    await pump(tester);

    controller.form.data.updateValue({'a': 'b'});
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.message.data, {'a': 'b'});
  });

  testWidgets('sends validate_only when the box is ticked', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.validateOnly, isTrue);
    expect(find.textContaining('Validated'), findsOne);
  });

  testWidgets('says sent, not validated, for a real send', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sent'), findsOne);
    expect(find.textContaining('Validated'), findsNothing);
  });

  testWidgets('explains why Send is disabled with no token', (tester) async {
    build(token: null);

    await pump(tester);

    expect(find.textContaining('token'), findsAtLeast(1));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('names the audience on the button, not always this device', (
    tester,
  ) async {
    // A button naming the wrong audience is worse than one naming none. It read
    // "Send to this device" unconditionally until a target could be chosen.
    build();
    await pump(tester);
    expect(find.text('Send to this device'), findsOne);

    controller.setTarget(const TopicTarget('news'));
    await tester.pumpAndSettle();

    expect(find.text('Send to topic "news"'), findsOne);
    expect(find.text('Send to this device'), findsNothing);

    controller.setTarget(const AllDevicesTarget());
    await tester.pumpAndSettle();

    expect(find.text('Send to every device'), findsOne);
  });

  testWidgets('reports an unmet need without blocking Send', (tester) async {
    // Neither may disable Send: the push is valid, only the behaviour it shows is
    // missing.
    build();
    await pump(tester);
    // The default scenario works, so the banner is mounted but takes no space.
    // Height, not `Size.zero`: the `ListView` hands its children a tight width, so
    // a shrunk banner measures 768 x 0.
    expect(tester.getSize(find.byType(ScenarioNeedsBanner)).height, 0);
    expect(find.byType(ManualStepsBlock), findsNothing);

    controller.applyScenario(
      scenarioGallery.firstWhere((s) => s.id == 'c7_standby_bucket'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Needs a manual step'), findsOne);
    expect(
      find.descendant(
        of: find.byType(ManualStepsBlock),
        matching: find.textContaining('set-standby-bucket'),
      ),
      findsOne,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a topic send needs no registration token', (tester) async {
    // A topic names its own audience, so requiring this device's token would block
    // every scenario in group J on a device that has never registered.
    build(token: null);
    await pump(tester);
    expect(controller.canSend, isFalse, reason: 'this device, no token');

    controller.setTarget(const TopicTarget('news'));
    await tester.pumpAndSettle();

    expect(controller.sendBlockedReason, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.target, const TopicTarget('news'));
  });

  testWidgets('a toggled field repaints, though no state scalar moved', (
    tester,
  ) async {
    // The guard for `SandboxState` deliberately having no `==`: ticking
    // `direct_boot_ok` moves none of its scalars, so value equality would make
    // `Cubit.emit` drop the new state and the checkbox would stay visibly unticked.
    // Asserted through the rendered `Checkbox`, since the model updating is exactly
    // what cannot prove the screen followed.
    build();
    await pump(tester);
    await tester.tap(find.text('android'));
    await tester.pumpAndSettle();

    final box = find.ancestor(
      of: find.text('direct_boot_ok'),
      matching: find.byType(CheckboxListTile),
    );
    // The open `android` section is taller than the screen, and a tap below the
    // viewport lands on nothing at all — silently.
    await tester.ensureVisible(box);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(box).value, isNull);

    await tester.tap(find.descendant(of: box, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();

    // `false`, not `true`: absent -> false is the transition that matters, since the
    // two are different messages to FCM.
    expect(tester.widget<CheckboxListTile>(box).value, isFalse);
    expect(
      find.descendant(of: box, matching: find.text('Not sent')),
      findsNothing,
      reason: 'the absent-value hint must go with the tick',
    );
  });

  testWidgets('renders a failure and keeps the payload', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    controller.form.data.updateValue({'kept': 'yes'});
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('The API is unreachable'), findsOne);
    expect(controller.form.data.value, {'kept': 'yes'});
  });
}
