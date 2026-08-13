import 'package:fcm_app/sandbox/forms/fcm_message_form.dart';
import 'package:fcm_app/ui/form/sections/message_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late FcmMessageForm form;

  setUp(() {
    form = FcmMessageForm()..initialize();
  });

  // The sections nest four levels deep, so an expanded `android.notification`
  // is far taller than the test surface. A scroll view is what lets
  // `ensureVisible` bring a nested header into reach before it is tapped.
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: MessageSection(form: form)),
      ),
    ),
  );

  /// Taps the [index]th header titled [title], scrolling it into view first.
  Future<void> expand(
    WidgetTester tester,
    String title, {
    int index = 0,
  }) async {
    final header = find.text(title).at(index);
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
  }

  testWidgets('starts collapsed, so the payload is not a wall of fields', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('message'), findsOne);
    expect(find.text('android'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets("expanding the root reveals each of FCM's five blocks", (
    tester,
  ) async {
    await pump(tester);
    await expand(tester, 'message');

    expect(find.text('notification'), findsOne);
    expect(find.text('android'), findsOne);
    expect(find.text('apns'), findsOne);
    expect(find.text('webpush'), findsOne);
    expect(find.text('fcm_options'), findsOne);
  });

  testWidgets('expanding android reveals its fields and its nested sections', (
    tester,
  ) async {
    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'android');

    expect(find.text('collapse_key'), findsOne);
    expect(find.text('ttl'), findsOne);
    expect(find.text('priority'), findsOne);
    expect(find.text('direct_boot_ok'), findsOne);
    // A second header of each name appears: android's own notification and
    // options blocks, beside the message-level ones.
    expect(find.text('notification'), findsNWidgets(2));
    expect(find.text('fcm_options'), findsNWidgets(2));
  });

  testWidgets('badges nothing while the whole payload is valid', (
    tester,
  ) async {
    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'android');

    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('badges an invalid field on its section and every ancestor', (
    tester,
  ) async {
    // 'blue' is not #rrggbb. The root's badge is the one that matters: without
    // it the error hides behind a collapsed section while Send sits disabled
    // for a reason nothing on screen explains.
    form.android.notification.color.updateValue('blue');

    await pump(tester);
    expect(find.byIcon(Icons.error_outline), findsOne);

    await expand(tester, 'message');
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));

    await expand(tester, 'android');
    expect(find.byIcon(Icons.error_outline), findsNWidgets(3));
  });

  testWidgets("badges the root for an invalid field of android's own", (
    tester,
  ) async {
    form.android.ttl.updateValue('later');

    await pump(tester);
    await expand(tester, 'message');

    // android and the root; the notification block below it stays clean.
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
  });

  testWidgets('badges all four ancestors of the deepest block', (tester) async {
    // light_settings is three levels below the root, so this is the fold that a
    // missed `isValid` override would break.
    form.android.notification.lightSettings.red.updateValue(2.5);

    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'android');
    // The second 'notification' header is android's, not the message's.
    await expand(tester, 'notification', index: 1);
    await expand(tester, 'light_settings');

    expect(find.byIcon(Icons.error_outline), findsNWidgets(4));
    expect(find.text('light_on_duration'), findsOne);
  });

  testWidgets('renders apns as free-form rows rather than as fields', (
    tester,
  ) async {
    form.apns.payload.updateValue({
      'aps': {
        'alert': {'title': 'Hi'},
      },
    });

    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'apns');

    expect(find.text('headers'), findsOne);
    expect(find.text('payload'), findsOne);
    expect(find.widgetWithText(TextField, 'aps.alert.title'), findsOne);
  });

  testWidgets('renders webpush with its own options block', (tester) async {
    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'webpush');

    expect(find.text('headers'), findsOne);
    expect(find.text('notification'), findsNWidgets(2));
    expect(find.text('fcm_options'), findsNWidgets(2));
  });

  testWidgets('binds a text field back to its input', (tester) async {
    await pump(tester);
    await expand(tester, 'message');
    await expand(tester, 'notification');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'title'),
      'Hello',
    );

    expect(form.notification.title.value, 'Hello');
  });
}
