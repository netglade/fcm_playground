import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

// The form is taller than the framework's default 800x600 test surface, and
// Flutter's scrollable elements report content below the fold as "offstage"
// (see `SliverMultiBoxAdaptorElement.debugVisitOnstageChildren`), which is
// exactly what `find.byType`/`tester.tap` skip by default. A generous surface
// keeps every field reachable without scrolling, matching a real device far
// better than the default does.
Future<void> _pumpView(
  WidgetTester tester,
  SandboxController controller,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SandboxView(controller: controller)),
    ),
  );
}

SandboxController _controller(
  FakeNotificationSender sender, {
  String? token = 'device-token',
}) => SandboxController(sender: sender, readToken: () => token);

Finder _field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

void main() {
  group('SandboxView', () {
    testWidgets('shows a chip per gallery scenario', (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      for (final scenario in notificationGallery) {
        expect(find.text(scenario.label), findsOneWidget);
      }
    });

    testWidgets('opens prefilled from the first scenario', (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      expect(find.text(notificationGallery.first.draft.title), findsOneWidget);
    });

    testWidgets('tapping a scenario replaces the form contents', (
      tester,
    ) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));
      final promo = notificationGallery.firstWhere((s) => s.id == 'promo');

      await tester.tap(find.text(promo.label));
      await tester.pumpAndSettle();

      expect(find.text(promo.draft.title), findsWidgets);
      expect(find.text(promo.draft.body), findsOneWidget);
    });

    testWidgets(
      'clearing the title shows the validator\'s message and disables sending',
      (tester) async {
        final sender = FakeNotificationSender();
        await _pumpView(tester, _controller(sender));

        await tester.enterText(_field('Title'), '');
        await tester.pump();

        expect(find.text('must not be blank'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets('says why it cannot send when there is no token', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _controller(FakeNotificationSender(), token: null),
      );

      expect(find.text('No registration token yet.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('sending hands the fake sender the edited draft', (
      tester,
    ) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.enterText(_field('Title'), 'Hand-written');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(sender.lastRequest?.draft.title, 'Hand-written');
      expect(sender.lastRequest?.token, 'device-token');
    });

    testWidgets('reports the payload id that will appear in the inbox', (
      tester,
    ) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('sandbox-1'), findsOneWidget);
    });

    testWidgets('shows the failure and keeps the form contents', (
      tester,
    ) async {
      final sender = FakeNotificationSender()
        ..failWith = StateError('functions unreachable');
      await _pumpView(tester, _controller(sender));
      await tester.enterText(_field('Title'), 'Still here');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('functions unreachable'), findsOneWidget);
      expect(find.text('Still here'), findsOneWidget);
    });

    testWidgets(
      'turning off "Show as notification" still requires a title, because '
      'the payload carries it either way',
      (tester) async {
        await _pumpView(tester, _controller(FakeNotificationSender()));
        await tester.enterText(_field('Title'), '');
        await tester.enterText(_field('Body'), '');
        await tester.pump();

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(find.text('must not be blank'), findsWidgets);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets('adding an extra data key sends it', (tester) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.tap(find.text('Add key/value'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Key').last, 'campaign');
      await tester.enterText(_field('Value').last, 'summer');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        sender.lastRequest?.draft.data,
        containsPair('campaign', 'summer'),
      );
    });

    testWidgets('a reserved extra data key is rejected before sending', (
      tester,
    ) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.tap(find.text('Add key/value'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Key').last, 'id');
      await tester.pump();

      expect(find.textContaining('written by the sender'), findsOneWidget);
      expect(sender.lastRequest, isNull);
    });
  });
}
