import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
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

  group('open versus closed', () {
    Color? titleColour(WidgetTester tester) =>
        tester.widget<Text>(find.text('Android')).style?.color;

    testWidgets('dims a closed section and brightens it when opened', (
      tester,
    ) async {
      // Asserted on the rendered title rather than the tile's collapsedTextColor:
      // the theme bakes a colour into titleMedium and an explicit colour on the Text
      // beats the tile's pair, so setting those alone changes nothing visible.
      await pump(tester, isValid: true);
      final closed = titleColour(tester);

      await tester.tap(find.text('Android'));
      await tester.pumpAndSettle();

      expect(closed, isNotNull);
      expect(titleColour(tester), isNotNull);
      expect(
        titleColour(tester),
        isNot(closed),
        reason: 'a closed header must not read the same as an open one',
      );
    });

    testWidgets('uses the scheme colours rather than arbitrary ones', (
      tester,
    ) async {
      // isNot(closed) alone would pass for any two colours, including two that
      // are indistinguishable on screen or that ignore the theme entirely.
      await pump(tester, isValid: true);
      final scheme = Theme.of(
        tester.element(find.byType(ExpansionTile)),
      ).colorScheme;

      expect(titleColour(tester), scheme.onSurfaceVariant);

      await tester.tap(find.text('Android'));
      await tester.pumpAndSettle();

      expect(titleColour(tester), scheme.onSurface);
    });

    testWidgets('a section that starts open reads as open', (tester) async {
      // The root starts expanded, so its state has to be seeded, not merely toggled.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormSection(
              title: 'Android',
              isValid: true,
              initiallyExpanded: true,
              children: [Text('a field')],
            ),
          ),
        ),
      );
      final scheme = Theme.of(
        tester.element(find.byType(ExpansionTile)),
      ).colorScheme;

      expect(titleColour(tester), scheme.onSurface);
    });
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

      // Three open sections, three rails. Material puts its own ShapeDecoration
      // boxes in the tree, so match on a left-only border rather than the type.
      final rails = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border)
          .whereType<Border>()
          .where((border) => border.bottom == BorderSide.none)
          .toList();

      expect(rails, hasLength(3));
      // A different colour per rail, which is what tells two open siblings at
      // different depths apart.
      expect(rails.map((rail) => rail.left.color).toSet(), hasLength(3));
    });
  });
}
