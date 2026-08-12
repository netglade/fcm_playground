import 'package:fcm_app/ui/form/form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isValid,
    bool expanded = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormSection(
            title: 'Android',
            isValid: isValid,
            children: const [Text('a field')],
          ),
        ),
      ),
    );
    if (expanded) {
      await tester.tap(find.text('Android'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('starts collapsed, so ten sections do not fill the screen', (
    tester,
  ) async {
    await pump(tester, isValid: true);

    expect(find.text('a field'), findsNothing);
  });

  testWidgets('reveals its children when tapped', (tester) async {
    await pump(tester, isValid: true, expanded: true);

    expect(find.text('a field'), findsOne);
  });

  testWidgets('shows no badge while valid', (tester) async {
    await pump(tester, isValid: true);

    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('badges an invalid section, so an error cannot hide collapsed', (
    tester,
  ) async {
    await pump(tester, isValid: false);

    expect(find.byIcon(Icons.error_outline), findsOne);
  });

  testWidgets('keeps the badge while expanded', (tester) async {
    await pump(tester, isValid: false, expanded: true);

    expect(find.byIcon(Icons.error_outline), findsOne);
    expect(find.text('a field'), findsOne);
  });
}
