import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/ui/inbox_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_source.dart';

Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-06T09:30:00Z',
  'deepLink': '/builds/42',
};

void main() {
  late FakePushSource source;
  late PushInbox inbox;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InboxView(inbox: inbox)),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    source = FakePushSource();
  });

  tearDown(() async {
    inbox.dispose();
    await source.dispose();
  });

  testWidgets('shows an empty state before anything arrives', (tester) async {
    inbox = PushInbox(source)..listen();

    await pumpApp(tester);

    expect(find.text('No pushes received yet.'), findsOne);
  });

  testWidgets('renders a received message with its data keys', (tester) async {
    inbox = PushInbox(source)..listen();
    await pumpApp(tester);

    source.emit(payload());
    await tester.pumpAndSettle();

    expect(find.text('Build finished'), findsOne);
    expect(find.textContaining('deepLink'), findsOne);
    // The id is what lets the sandbox's "Sent · id sandbox-…" report be
    // matched against the message that actually arrived.
    expect(find.textContaining('msg-1'), findsOne);
    expect(find.text('09:30'), findsOne);
    expect(find.text('No pushes received yet.'), findsNothing);
  });

  testWidgets('shows the registration token once resolved', (tester) async {
    inbox = PushInbox(source)..listen();
    await inbox.refreshToken();

    await pumpApp(tester);

    expect(find.text('fake-token'), findsOne);
  });

  testWidgets('surfaces a setup error in a banner', (tester) async {
    inbox = PushInbox(source, setupError: 'Firebase is not configured');

    await pumpApp(tester);

    expect(find.text('Firebase is not configured'), findsOne);
    expect(find.byType(ColoredBox), findsAtLeast(1));
  });

  testWidgets('counts malformed payloads', (tester) async {
    inbox = PushInbox(source)..listen();
    await pumpApp(tester);

    source.emit({'id': 'broken'});
    await tester.pumpAndSettle();

    expect(find.text('1 malformed payload(s) dropped'), findsOne);
  });
}
