import 'package:fcm_app/pages/sandbox/cubit/sandbox_send_state.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_result_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final response = SendMessageResponse(
    messageId: 'projects/p/messages/0:17',
    sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    traceId: 'a1b2c3-deadbeef',
  );

  Future<void> pump(
    WidgetTester tester,
    SandboxSendState state, {
    bool validateOnly = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SendResultCard(
          state,
          validateOnly: validateOnly,
          onNotReceived: (_) => Future<void>.value(),
        ),
      ),
    ),
  );

  /// First rather than only: a real send also carries the not-received button.
  String textOf(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text).first).data!;

  testWidgets('shows the trace id after a real send', (tester) async {
    // Without it on screen the id exists only in the server's database, and the
    // person holding the phone cannot say which row is theirs.
    await pump(tester, SandboxSent(response));

    expect(textOf(tester), contains('a1b2c3-deadbeef'));
    expect(
      textOf(tester),
      contains('projects/p/messages/0:17'),
      reason: 'the FCM message id must not be dropped to make room',
    );
  });

  testWidgets('shows the trace id after a validate-only send', (tester) async {
    // A validated send still mints a trace id and still records events, so
    // hiding it here would make half the traces unfindable.
    await pump(tester, SandboxSent(response), validateOnly: true);

    expect(textOf(tester), contains('a1b2c3-deadbeef'));
    expect(textOf(tester), contains('Validated'));
    expect(
      textOf(tester),
      isNot(contains('should appear in the Inbox')),
      reason: 'a validated send delivered nothing',
    );
  });

  testWidgets('says nothing at all before a send', (tester) async {
    await pump(tester, const SandboxIdle());

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows no trace id for a failure', (tester) async {
    // There is no response and therefore no id. Showing a stale one from a
    // previous send would point at the wrong message.
    await pump(tester, const SandboxFailed('FCM refused it'));

    expect(textOf(tester), 'FCM refused it');
  });
}
