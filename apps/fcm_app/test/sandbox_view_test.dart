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

  // The default 800x600 test surface is shorter than this page once the
  // first scenario group is expanded, so the editor and Send button sit
  // beyond the outer ListView sliver's built extent: `find` will not even
  // locate them, let alone `tap` them, until the list is scrolled.
  // `scrollUntilVisible` stops as soon as a widget's leading edge is built,
  // which is enough for `find`/`enterText`/`tester.widget`, but `tap` aims
  // at the widget's centre — so a tap additionally needs the extra drag.
  Finder scrollable() => find.byType(Scrollable).first;

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 300, scrollable: scrollable());
  }

  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await scrollIntoView(tester, finder);
    await tester.pumpAndSettle();
    // scrollUntilVisible stops as soon as the widget's leading edge is
    // built, which can leave its centre — where tap() aims — above or below
    // the 800x600 surface. Nudge the exact remaining distance so the centre
    // lands mid-screen before tapping.
    final center = tester.getCenter(finder);
    await tester.drag(scrollable(), Offset(0, 300 - center.dy));
    await tester.pumpAndSettle();
    await tester.tap(finder);
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

  testWidgets('shows the first group\'s scenarios and their tags', (
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

  testWidgets('opens on the first scenario, with its payload in the editor', (
    tester,
  ) async {
    build();

    await pump(tester);
    await scrollIntoView(tester, find.byType(TextField));

    expect(find.textContaining('"notification"'), findsOne);
  });

  testWidgets('loads a scenario from another group when tapped', (
    tester,
  ) async {
    build();
    await pump(tester);
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'data_only');

    await scrollAndTap(tester, find.text(dataOnly.group));
    await scrollAndTap(tester, find.text(dataOnly.title));
    await scrollIntoView(tester, find.byType(TextField));

    expect(find.textContaining('"event"'), findsOne);
  });

  testWidgets('renders a parse error and disables Send', (tester) async {
    build();
    await pump(tester);

    await scrollIntoView(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '{not json');
    await tester.pumpAndSettle();

    expect(find.textContaining('FormatException'), findsNothing);
    await scrollIntoView(tester, find.byType(FilledButton));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('names the offending field for an unknown key', (tester) async {
    build();
    await pump(tester);

    await scrollIntoView(tester, find.byType(TextField));
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

    await scrollIntoView(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '{"data": {"a": "b"}}');
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byType(FilledButton));

    expect(sender.sent.single.message.data, {'a': 'b'});
  });

  testWidgets('sends validate_only when the box is ticked', (tester) async {
    build();
    await pump(tester);

    await scrollAndTap(tester, find.byType(Checkbox));
    await scrollAndTap(tester, find.byType(FilledButton));

    expect(sender.sent.single.validateOnly, isTrue);
    expect(find.textContaining('Validated'), findsOne);
  });

  testWidgets('says sent, not validated, for a real send', (tester) async {
    build();
    await pump(tester);

    await scrollAndTap(tester, find.byType(FilledButton));

    expect(find.textContaining('Sent'), findsOne);
    expect(find.textContaining('Validated'), findsNothing);
  });

  testWidgets('explains why Send is disabled with no token', (tester) async {
    build(token: null);

    await pump(tester);
    await scrollIntoView(tester, find.byType(FilledButton));

    expect(find.textContaining('token'), findsAtLeast(1));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('renders a failure and keeps the payload', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    await scrollIntoView(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '{"data": {"kept": "yes"}}');
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byType(FilledButton));

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.textContaining('kept'), findsOne);
  });
}
