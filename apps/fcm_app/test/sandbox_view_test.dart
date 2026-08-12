import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
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

  Finder fieldLabelled(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextField));

  final first = notificationGallery.first;
  final promo = notificationGallery.firstWhere(
    (scenario) => scenario.id == 'promo',
  );

  tearDown(() => controller.dispose());

  testWidgets('opens on the first preset', (tester) async {
    build();

    await pump(tester);

    expect(find.widgetWithText(TextField, first.draft.title), findsOne);
  });

  testWidgets('offers every preset as a chip', (tester) async {
    build();

    await pump(tester);

    for (final scenario in notificationGallery) {
      expect(find.text(scenario.label), findsOne, reason: scenario.id);
    }
  });

  testWidgets('replaces the fields when a preset is tapped', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.text(promo.label));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, promo.draft.title), findsOne);
    expect(find.widgetWithText(TextField, 'campaign'), findsOne);
    expect(find.widgetWithText(TextField, first.draft.title), findsNothing);
  });

  testWidgets('shows a problem against the field and blocks Send', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), '');
    await tester.pumpAndSettle();

    expect(find.text('must not be blank'), findsOne);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('explains why Send is disabled with no token', (tester) async {
    build(token: null);

    await pump(tester);

    expect(find.textContaining('nowhere to send'), findsOne);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sends the edited draft to this device', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), 'Hand written');
    await tester.enterText(fieldLabelled('Body'), 'From the sandbox');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.token, 'device-token');
    expect(sender.sent.single.draft.title, 'Hand written');
    expect(sender.sent.single.draft.body, 'From the sandbox');
  });

  testWidgets('sends a data row the user added', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.text('Add key/value'));
    await tester.pumpAndSettle();
    final keyFields = find.widgetWithText(TextField, 'key');
    await tester.enterText(keyFields.last, 'ticket');
    await tester.enterText(
      find.widgetWithText(TextField, 'value').last,
      'ABC-1',
    );
    // The default test surface is a fixed 800x600, and the extra row's blank-key
    // hint pushes Send below the sliver's built extent, so it does not even exist
    // in the element tree yet; scroll it into the built range first...
    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // ...then keep scrolling: scrollUntilVisible stops as soon as the widget's
    // leading edge crosses into view, which can still leave its center (where
    // tap() aims) below the fold on this landscape-tablet-shaped viewport.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.draft.data['ticket'], 'ABC-1');
  });

  testWidgets('removes a data row', (tester) async {
    build();
    await pump(tester);
    final rowsBefore = find
        .byIcon(Icons.remove_circle_outline)
        .evaluate()
        .length;

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.remove_circle_outline),
      findsNWidgets(rowsBefore - 1),
    );
  });

  testWidgets('shows the payload id after a send, so it can be matched', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('api-1754812345678901'), findsOne);
  });

  testWidgets('renders a failure and keeps what was typed', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), 'Kept');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.widgetWithText(TextField, 'Kept'), findsOne);
  });
}
