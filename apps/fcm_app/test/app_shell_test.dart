import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/fcm_sample_app.dart';
import 'package:fcm_app/ui/message_detail_page.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fake_notification_sender.dart';
import 'fake_push_payload_store.dart';
import 'fake_push_source.dart';

Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-11T09:30:00Z',
};

void main() {
  setUpAll(GladeForms.initialize);

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

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

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

  testWidgets('offers all three destinations in the drawer', (tester) async {
    await pumpApp(tester);

    await openDrawer(tester);

    expect(find.text('Inbox'), findsOne);
    expect(find.text('Scenarios'), findsOne);
    expect(find.text('Sandbox'), findsOne);
  });

  testWidgets('switches to the scenarios page and retitles the bar', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Scenarios'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 1);
    expect(find.widgetWithText(AppBar, 'Scenarios'), findsOne);
  });

  testWidgets('switches to the sandbox and retitles the bar', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 2);
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

  testWidgets('tapping a scenario switches to the sandbox with it loaded', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDrawer(tester);
    await tester.tap(find.text('Scenarios'));
    await tester.pumpAndSettle();
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'data_only');

    // Reaching a later group is a scroll within the gallery's own page,
    // unrelated to the bug this change fixes: that was the editor on the
    // *Sandbox* page sitting below the fold with nothing above it.
    await scrollIntoView(tester, find.text(dataOnly.group));
    await tester.tap(find.text(dataOnly.group));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.text(dataOnly.title));
    await tester.tap(find.text(dataOnly.title));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 2);
    expect(find.widgetWithText(AppBar, 'Sandbox'), findsOne);
    expect(sandbox.selectedScenario?.id, dataOnly.id);
    expect(sandbox.form.data.value, dataOnly.payloadTemplate['data']);
  });

  Future<void> openSandbox(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the detail page for a tapped notification', (
    tester,
  ) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped');
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(inbox.hasPendingOpen, isFalse);
  });

  testWidgets('leaves the sandbox for the inbox when a tap arrives', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSandbox(tester);

    inbox.requestOpen('never-seen');
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 0);
    expect(find.byType(MessageDetailPage), findsNothing);
  });

  testWidgets('opens the page once the message catches up', (tester) async {
    await pumpApp(tester);

    inbox.requestOpen('late');
    await tester.pumpAndSettle();
    expect(find.byType(MessageDetailPage), findsNothing);
    source.emit(payload(id: 'late'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('does not open the page twice for one tap', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped');
    await tester.pumpAndSettle();
    source.emit(payload(id: 'unrelated'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('drains pending payloads when the app resumes', (tester) async {
    final store = FakePushPayloadStore();
    // A fresh source: setUp's `source` already has a listener from the outer
    // `inbox`, and a single-subscription stream accepts only one ever.
    inbox = PushInbox(FakePushSource(), store: store)..listen();
    sandbox = SandboxController(
      sender: FakeNotificationSender(),
      token: () => inbox.token,
    );
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
    store.pending.add(payload(id: 'while-away'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(inbox.messages.single.id, 'while-away');
  });
}
