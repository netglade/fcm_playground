import 'package:fcm_app/pages/sandbox/forms/fcm_message_form.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/message_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late FcmMessageForm form;

  setUp(() {
    form = FcmMessageForm()..initialize();
  });

  // An expanded `android.notification` is far taller than the test surface, so a
  // scroll view is what lets `ensureVisible` reach a nested header.
  Future<void> pump(WidgetTester tester) =>
      pumpApp(tester, SingleChildScrollView(child: MessageSection(form: form)));

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

  testWidgets("shows FCM's five blocks on arrival, with no field revealed", (
    tester,
  ) async {
    // Both halves matter: a wall of fields was the original defect, and one closed
    // tile hiding the whole payload would be no better.
    await pump(tester);

    expect(find.text('message'), findsOne);
    expect(find.text('notification'), findsOne);
    expect(find.text('android'), findsOne);
    expect(find.text('apns'), findsOne);
    expect(find.text('webpush'), findsOne);
    expect(find.text('fcm_options'), findsOne);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('the blocks are reachable without scrolling the page', (
    tester,
  ) async {
    // Every top-level block must be hit-testable straight after a pump.
    await pump(tester);

    for (final block in const [
      'notification',
      'android',
      'apns',
      'webpush',
      'fcm_options',
    ]) {
      expect(tester.getRect(find.text(block).first).top, lessThan(600));
    }
  });

  testWidgets('expanding android reveals its fields and its nested sections', (
    tester,
  ) async {
    await pump(tester);
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
    await expand(tester, 'android');

    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('badges an invalid field on its section and every ancestor', (
    tester,
  ) async {
    // 'blue' is not #rrggbb. Without the root's badge the error hides behind a
    // collapsed section while Send sits disabled for an unexplained reason.
    form.android.notification.color.updateValue('blue');

    await pump(tester);

    // The root and android, both visible on arrival, before anything is opened.
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));

    // Opening android reveals the notification block carrying the bad field.
    await expand(tester, 'android');
    expect(find.byIcon(Icons.error_outline), findsNWidgets(3));
  });

  testWidgets("badges the root for an invalid field of android's own", (
    tester,
  ) async {
    form.android.ttl.updateValue('later');

    await pump(tester);

    // android and the root; the notification block below it stays clean.
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
  });

  testWidgets('badges all four ancestors of the deepest block', (tester) async {
    // light_settings is three levels below the root, so this is the fold that a
    // missed `isValid` override would break.
    form.android.notification.lightSettings.red.updateValue(2.5);

    await pump(tester);
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
    await expand(tester, 'apns');

    expect(find.text('headers'), findsOne);
    expect(find.text('payload'), findsOne);
    expect(find.widgetWithText(TextField, 'aps.alert.title'), findsOne);
  });

  testWidgets('renders webpush with its own options block', (tester) async {
    await pump(tester);
    await expand(tester, 'webpush');

    expect(find.text('headers'), findsOne);
    expect(find.text('notification'), findsNWidgets(2));
    expect(find.text('fcm_options'), findsNWidgets(2));
  });

  testWidgets('binds a text field back to its input', (tester) async {
    await pump(tester);
    await expand(tester, 'notification');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'title'),
      'Hello',
    );

    expect(form.notification.title.value, 'Hello');
  });
}
