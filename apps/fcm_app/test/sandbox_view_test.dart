import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

void main() {
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

  testWidgets('shows the editor without scrolling, on arrival', (tester) async {
    build();

    await pump(tester);

    // The reported bug was that no editable field was on screen. This is the
    // regression test for it: found with no scroll helper of any kind.
    expect(find.byType(TextField), findsOne);
  });

  testWidgets('opens with the first scenario\'s payload in the editor', (
    tester,
  ) async {
    build();

    await pump(tester);

    expect(find.textContaining('"notification"'), findsOne);
  });

  testWidgets('names the loaded scenario in the header', (tester) async {
    build();

    await pump(tester);

    expect(find.text(controller.selectedScenario!.title), findsOne);
  });

  testWidgets('renders a parse error and disables Send', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{not json');
    await tester.pumpAndSettle();

    expect(find.textContaining('FormatException'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('names the offending field for an unknown key', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(
      find.byType(TextField),
      '{"notification": {"titel": "typo"}}',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('unknown field "titel"'), findsOne);
  });

  testWidgets('sends the edited payload', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{"data": {"a": "b"}}');
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

  testWidgets('renders a failure and keeps the payload', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{"data": {"kept": "yes"}}');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.textContaining('kept'), findsOne);
  });
}
