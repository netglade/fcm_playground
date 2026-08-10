import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';
import 'fake_push_source.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final inbox = PushInbox(FakePushSource())..listen();

  await tester.pumpWidget(
    MaterialApp(
      home: AppShell(
        inbox: inbox,
        sandbox: SandboxController(
          sender: FakeNotificationSender(),
          readToken: () => 'device-token',
        ),
      ),
    ),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('opens on the inbox', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Push inbox'), findsOneWidget);
      expect(find.text('No pushes received yet.'), findsOneWidget);
    });

    testWidgets('offers both destinations in the drawer', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Sandbox'), findsOneWidget);
    });

    testWidgets(
      'switching to the sandbox retitles the bar and closes the drawer',
      (tester) async {
        await _pumpApp(tester);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sandbox'));
        await tester.pumpAndSettle();

        expect(find.text('Sandbox'), findsOneWidget);
        expect(find.text('No pushes received yet.'), findsNothing);
        expect(find.text('Inbox'), findsNothing, reason: 'drawer should close');
      },
    );

    testWidgets('switching back returns to the inbox', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sandbox'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Push inbox'), findsOneWidget);
      expect(find.text('No pushes received yet.'), findsOneWidget);
    });
  });
}
