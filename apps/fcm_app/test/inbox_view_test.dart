import 'package:fcm_app/push/inbox_cubit.dart';
import 'package:fcm_app/push/push_repository.dart';
import 'package:fcm_app/sandbox/sandbox_cubit.dart';
import 'package:fcm_app/ui/fcm_sample_app.dart';
import 'package:fcm_app/ui/message_detail_page.dart';
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
  'sentAt': '2026-08-06T09:30:00Z',
  'deepLink': '/builds/42',
};

void main() {
  setUpAll(GladeForms.initialize);

  late FakePushSource source;
  late PushRepository repository;
  late InboxCubit inbox;
  late SandboxCubit sandbox;

  Future<void> pumpApp(WidgetTester tester) async {
    sandbox = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => inbox.state.token,
    );
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
  }

  setUp(() {
    source = FakePushSource();
  });

  tearDown(() async {
    await sandbox.close();
    await inbox.close();
    repository.dispose();
    await source.dispose();
  });

  testWidgets('shows an empty state before anything arrives', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);

    await pumpApp(tester);

    expect(find.text('No pushes received yet.'), findsOne);
  });

  testWidgets('renders a received message with its data keys', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit(payload());
    await tester.pumpAndSettle();

    expect(find.text('Build finished'), findsOne);
    expect(find.textContaining('deepLink'), findsOne);
    expect(find.text('09:30'), findsOne);
    expect(find.text('No pushes received yet.'), findsNothing);
  });

  testWidgets('shows the registration token once resolved', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await repository.refreshToken();

    await pumpApp(tester);

    expect(find.text('fake-token'), findsOne);
  });

  testWidgets('surfaces a setup error in a banner', (tester) async {
    repository = PushRepository(
      source,
      store: FakePushPayloadStore(),
      setupError: 'Firebase is not configured',
    );
    inbox = InboxCubit(repository);

    await pumpApp(tester);

    expect(find.text('Firebase is not configured'), findsOne);
    expect(find.byType(ColoredBox), findsAtLeast(1));
  });

  testWidgets('counts malformed payloads', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit({'id': 'broken'});
    await tester.pumpAndSettle();

    expect(find.text('1 malformed payload(s) dropped'), findsOne);
  });

  testWidgets('shows a placeholder for a push with no title', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit({
      'id': 'silent-1',
      'sentAt': '2026-08-06T09:30:00Z',
      'event': 'sync',
    });
    await tester.pumpAndSettle();

    expect(find.text('(no title)'), findsOne);
    expect(find.textContaining('event'), findsOne);
    expect(find.text('1 malformed payload(s) dropped'), findsNothing);
  });

  testWidgets('opens the detail page when a row is tapped', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(find.text('/builds/42'), findsOne);
  });

  testWidgets('comes back to the inbox from the detail page', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsNothing);
    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
  });
}
