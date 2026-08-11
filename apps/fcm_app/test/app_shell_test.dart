import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/fcm_sample_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';
import 'fake_push_payload_store.dart';
import 'fake_push_source.dart';

void main() {
  late FakePushSource source;
  late PushInbox inbox;
  late SandboxController sandbox;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }

  int? selectedDestination(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

  setUp(() {
    source = FakePushSource();
    inbox = PushInbox(source, store: FakePushPayloadStore())..listen();
    sandbox = SandboxController(
      sender: FakeNotificationSender(),
      token: () => inbox.token,
    );
  });

  tearDown(() async {
    sandbox.dispose();
    inbox.dispose();
    await source.dispose();
  });

  testWidgets('opens on the inbox', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
    expect(selectedDestination(tester), 0);
  });

  testWidgets('offers both destinations in the drawer', (tester) async {
    await pumpApp(tester);

    await openDrawer(tester);

    expect(find.text('Inbox'), findsOne);
    expect(find.text('Sandbox'), findsOne);
  });

  testWidgets('switches to the sandbox and retitles the bar', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 1);
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
}
