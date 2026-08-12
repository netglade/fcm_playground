import 'package:fcm_app/ui/form/path_rows_field.dart';
import 'package:fcm_app/ui/form/string_list_rows.dart';
import 'package:fcm_app/ui/form/string_map_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringMapRows', () {
    Map<String, String>? lastValue;

    Future<void> pumpMap(WidgetTester tester, Map<String, String> value) {
      lastValue = null;

      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringMapRows(
              label: 'Data',
              value: value,
              onChanged: (next) => lastValue = next,
            ),
          ),
        ),
      );
    }

    testWidgets('starts with no rows when the value is empty', (tester) async {
      await pumpMap(tester, const {});

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders a row per entry', (tester) async {
      await pumpMap(tester, const {'event': 'build_finished'});

      expect(find.widgetWithText(TextField, 'event'), findsOne);
      expect(find.widgetWithText(TextField, 'build_finished'), findsOne);
    });

    testWidgets('reports a new row', (tester) async {
      await pumpMap(tester, const {});

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'k');
      await tester.enterText(find.byType(TextField).last, 'v');

      expect(lastValue, {'k': 'v'});
    });

    testWidgets('reports a removal', (tester) async {
      await pumpMap(tester, const {'a': '1', 'b': '2'});

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle();

      expect(lastValue, {'b': '2'});
    });

    testWidgets('drops a row with a blank key', (tester) async {
      await pumpMap(tester, const {});

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'orphan');

      expect(lastValue, isEmpty);
    });
  });

  group('StringListRows', () {
    List<String>? lastList;

    Future<void> pumpList(WidgetTester tester, List<String> value) {
      lastList = null;

      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StringListRows(
              label: 'Args',
              value: value,
              onChanged: (next) => lastList = next,
            ),
          ),
        ),
      );
    }

    testWidgets('starts with no rows when the value is empty', (tester) async {
      await pumpList(tester, const []);

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders a row per item', (tester) async {
      await pumpList(tester, const ['click_action']);

      expect(find.widgetWithText(TextField, 'click_action'), findsOne);
    });

    testWidgets('reports a new row', (tester) async {
      await pumpList(tester, const []);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'x');

      expect(lastList, ['x']);
    });

    testWidgets('reports a removal', (tester) async {
      await pumpList(tester, const ['a', 'b']);

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle();

      expect(lastList, ['b']);
    });

    testWidgets('drops a row with a blank entry', (tester) async {
      await pumpList(tester, const []);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(lastList, isEmpty);
    });
  });

  group('PathRowsField', () {
    Map<String, Object?>? lastPaths;

    Future<void> pumpPaths(WidgetTester tester, Map<String, Object?> value) {
      lastPaths = null;

      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PathRowsField(
              label: 'Payload',
              value: value,
              onChanged: (next) => lastPaths = next,
            ),
          ),
        ),
      );
    }

    testWidgets('shows a nested payload as dotted rows', (tester) async {
      await pumpPaths(tester, const {
        'aps': {
          'alert': {'title': 'Hi'},
          'badge': 1,
        },
      });

      expect(find.widgetWithText(TextField, 'aps.alert.title'), findsOne);
      expect(find.widgetWithText(TextField, 'aps.badge'), findsOne);
    });

    testWidgets('reports an edited row as nested structure', (tester) async {
      await pumpPaths(tester, const {});

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'aps.badge');
      await tester.enterText(find.byType(TextField).last, '2');

      expect(lastPaths, {
        'aps': {'badge': 2},
      });
    });
  });
}
