import 'package:core/core.dart';
import 'package:fcm_app/domains/push/pressed_action.dart';
import 'package:fcm_app/pages/inbox/message_detail_page.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  final message = PushMessage(
    id: 'api-1754812345678901',
    title: 'Build finished',
    body: 'Release 1.0.0 is ready.',
    sentAt: DateTime.utc(2026, 8, 11, 9, 30),
    data: const {'event': 'build_finished', 'deepLink': '/builds/42'},
  );

  Future<void> pump(WidgetTester tester, PushMessage subject) =>
      pumpApp(tester, MessageDetailPage(subject));

  testWidgets('shows the title in the app bar and the body', (tester) async {
    await pump(tester, message);

    expect(find.widgetWithText(AppBar, 'Build finished'), findsOne);
    expect(find.text('Release 1.0.0 is ready.'), findsOne);
  });

  testWidgets('shows the payload id, which matches what the API reported', (
    tester,
  ) async {
    await pump(tester, message);

    expect(find.text('api-1754812345678901'), findsOne);
  });

  testWidgets('shows when it was sent, in UTC', (tester) async {
    await pump(tester, message);

    expect(find.textContaining('2026-08-11'), findsOne);
  });

  testWidgets('shows every data key and its value', (tester) async {
    await pump(tester, message);

    expect(find.text('event'), findsOne);
    expect(find.text('build_finished'), findsOne);
    expect(find.text('deepLink'), findsOne);
    expect(find.text('/builds/42'), findsOne);
  });

  testWidgets('says so when there is no extra data', (tester) async {
    await pump(
      tester,
      PushMessage(
        id: 'plain',
        title: 'Hello',
        body: 'Nothing but a title and a body.',
        sentAt: DateTime.utc(2026, 8, 11),
      ),
    );

    expect(find.text('No extra data keys.'), findsOne);
  });

  testWidgets('can be popped, so a tap is not a dead end', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => MessageDetailPage(message)),
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Release 1.0.0 is ready.'), findsOne);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOne);
  });

  testWidgets('names the pressed action by its label and its state', (
    tester,
  ) async {
    await pumpApp(
      tester,
      MessageDetailPage(
        PushMessage(
          id: 'msg-1',
          title: 'Build failed',
          body: 'Retry or open?',
          sentAt: DateTime.utc(2026, 8, 24, 9),
          data: const {'actions': 'retry:Retry|open:Open build'},
        ),
        pressedAction: const PressedAction(
          actionId: 'retry',
          from: OpenedFrom.killed,
        ),
      ),
    );

    expect(find.text('Opened by action: Retry'), findsOne);
    expect(find.text('from: killed'), findsOne);
  });

  testWidgets('says nothing when no action was pressed', (tester) async {
    await pumpApp(
      tester,
      MessageDetailPage(
        PushMessage(
          id: 'msg-1',
          title: 'Build failed',
          body: 'Retry or open?',
          sentAt: DateTime.utc(2026, 8, 24, 9),
        ),
      ),
    );

    expect(find.textContaining('Opened by action'), findsNothing);
  });

  testWidgets('falls back to the id when the payload names no such action', (
    tester,
  ) async {
    await pumpApp(
      tester,
      MessageDetailPage(
        PushMessage(
          id: 'msg-1',
          title: 'Build failed',
          body: 'Retry or open?',
          sentAt: DateTime.utc(2026, 8, 24, 9),
          data: const {'actions': 'open:Open build'},
        ),
        pressedAction: const PressedAction(
          actionId: 'retry',
          from: OpenedFrom.foreground,
        ),
      ),
    );

    expect(find.text('Opened by action: retry'), findsOne);
  });

  testWidgets('shows a reply the user typed in the shade', (tester) async {
    await pumpApp(
      tester,
      MessageDetailPage(
        PushMessage(
          id: 'msg-1',
          title: 'Ada',
          body: 'ready when you are',
          sentAt: DateTime.utc(2026, 8, 24, 9),
        ),
        reply: 'on my way',
      ),
    );

    expect(find.text('Replied: on my way'), findsOne);
  });

  testWidgets(
    'shows both cards when a message has a pressed action and a reply',
    (tester) async {
      await pumpApp(
        tester,
        MessageDetailPage(
          PushMessage(
            id: 'msg-1',
            title: 'Build failed',
            body: 'Retry or open?',
            sentAt: DateTime.utc(2026, 8, 24, 9),
            data: const {'actions': 'retry:Retry|open:Open build'},
          ),
          pressedAction: const PressedAction(
            actionId: 'retry',
            from: OpenedFrom.background,
          ),
          reply: 'on my way',
        ),
      );

      expect(find.text('Opened by action: Retry'), findsOne);
      expect(find.text('from: background'), findsOne);
      expect(find.text('Replied: on my way'), findsOne);
    },
  );

  testWidgets('says nothing when there is no reply', (tester) async {
    await pumpApp(
      tester,
      MessageDetailPage(
        PushMessage(
          id: 'msg-1',
          title: 'Ada',
          body: 'ready when you are',
          sentAt: DateTime.utc(2026, 8, 24, 9),
        ),
      ),
    );

    expect(find.textContaining('Replied:'), findsNothing);
  });
}
