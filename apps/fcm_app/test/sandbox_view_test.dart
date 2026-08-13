import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:fcm_app/ui/send_target_field.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fake_notification_sender.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late FakeNotificationSender sender;
  late SandboxController controller;

  void build({
    String? token = 'device-token',
    NotificationSendException? failure,
  }) {
    sender = FakeNotificationSender(failure: failure);
    controller = SandboxController(sender: sender, token: () => token);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SandboxView(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => controller.dispose());

  testWidgets('shows the payload form without scrolling, on arrival', (
    tester,
  ) async {
    build();

    await pump(tester);

    // The reported bug was that no editable surface was on screen. This is the
    // regression test for it: found with no scroll helper of any kind.
    expect(find.text('message'), findsOne);
  });

  testWidgets('every block is reachable without a scroll helper', (
    tester,
  ) async {
    // An editor below the fold that never mounted is what started this line of
    // work, so every top-level block of the payload must be on screen after
    // nothing but a pump.
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
    // Where a send goes matters more than what it says, and it is the one
    // choice that cannot be corrected by reading the payload back, so it heads
    // the page rather than trailing the 27 fields of `android.notification`.
    build();

    await pump(tester);

    expect(find.byType(SendTargetField).hitTestable(), findsOne);
    expect(
      tester.getTopLeft(find.byType(SendTargetField)).dy,
      lessThan(tester.getTopLeft(find.byType(CheckboxListTile)).dy),
    );
  });

  testWidgets('a field edited on arrival reaches the model', (tester) async {
    // The original bug was not that no field existed, but that reaching one
    // took a scroll the user did not know to make. One tap, no scrolling.
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
    // Send was the last child of the scrolling list, so on arrival it sat below
    // the fold and the lazy `ListView` had not even built it. Pinned in the
    // footer it is hit-testable straight after a pump, and stays so as sections
    // open: `android.notification` alone adds 27 fields.
    build();
    await pump(tester);

    expect(find.byType(FilledButton).hitTestable(), findsOne);

    await tester.tap(find.text('android'));
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton).hitTestable(), findsOne);
  });

  testWidgets('does not name the loaded scenario', (tester) async {
    // The gallery is where a scenario is chosen and named; repeating its title
    // here only pushes the payload further down a page whose whole layout is
    // arranged around what the user needs on arrival. The caveat below it stays,
    // because that is advice about sending rather than a label.
    build();

    await pump(tester);

    expect(find.text(controller.selectedScenario!.title), findsNothing);
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
    // Where a push goes is the one thing on this page a user cannot check by
    // reading the payload back, so a button naming the wrong audience is worse
    // than one naming none. It read "Send to this device" unconditionally until
    // a target could be chosen.
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

  testWidgets('a topic send needs no registration token', (tester) async {
    // A topic names its own audience, so requiring this device's token would
    // block the whole targeting feature — and every scenario in group J — on a
    // device that has never registered.
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
