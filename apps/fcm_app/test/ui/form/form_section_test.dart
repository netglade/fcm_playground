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

  group('depth', () {
    /// Pumps a section nested [levels] deep and opens every one of them.
    Future<void> pumpNested(WidgetTester tester, int levels) async {
      Widget leaf = const Text('a field');
      for (var level = levels; level >= 0; level--) {
        leaf = FormSection(
          title: 'level $level',
          isValid: true,
          initiallyExpanded: true,
          children: [leaf],
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: leaf)),
        ),
      );
      await tester.pumpAndSettle();
    }

    TextStyle styleOf(WidgetTester tester, String title) =>
        tester.widget<Text>(find.text(title)).style!;

    testWidgets('steps each level in, so nesting is visible as position', (
      tester,
    ) async {
      await pumpNested(tester, 3);

      // Strictly increasing left edges. Equal ones would render four levels as
      // one flat list.
      final lefts = [
        for (var level = 0; level <= 3; level++)
          tester.getRect(find.text('level $level')).left,
      ];
      for (var level = 1; level < lefts.length; level++) {
        expect(lefts[level], greaterThan(lefts[level - 1]));
      }
    });

    testWidgets('quietens each header, so depth reads without counting', (
      tester,
    ) async {
      await pumpNested(tester, 2);

      // Indentation alone is ambiguous once two siblings sit open at different
      // depths, so weight and size have to carry it too.
      expect(
        styleOf(tester, 'level 0').fontSize,
        greaterThan(styleOf(tester, 'level 2').fontSize!),
      );
      expect(styleOf(tester, 'level 0').fontWeight, equals(FontWeight.w700));
      expect(styleOf(tester, 'level 1').fontWeight, equals(FontWeight.w600));
    });

    testWidgets('draws one rail per open level', (tester) async {
      await pumpNested(tester, 2);

      // Three open sections, three rails — the guide that ties a field back to
      // the object it belongs to. Material puts its own ShapeDecoration boxes in
      // the tree, so match on a left-only border rather than on the type alone.
      final rails = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border)
          .whereType<Border>()
          .where((border) => border.bottom == BorderSide.none)
          .toList();

      expect(rails, hasLength(3));
      // Each rail is a different colour, which is what makes two open siblings
      // at different depths distinguishable rather than merely both railed.
      expect(rails.map((rail) => rail.left.color).toSet(), hasLength(3));
    });
  });
}
