import 'package:fcm_app/ui/form/enum_field.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'enum_field_model.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late EnumFieldModel model;

  setUp(() {
    model = EnumFieldModel()..initialize();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EnumField<AndroidMessagePriority>(
          label: 'Priority',
          input: model.priority,
          values: AndroidMessagePriority.values,
          labelOf: (value) => value.wireName,
        ),
      ),
    ),
  );

  testWidgets('starts unset, which is not the same as a chosen value', (
    tester,
  ) async {
    await pump(tester);

    expect(
      tester
          .widget<DropdownButtonFormField<AndroidMessagePriority?>>(
            find.byType(DropdownButtonFormField<AndroidMessagePriority?>),
          )
          .initialValue,
      isNull,
    );
    expect(model.priority.value, isNull);
  });

  testWidgets('offers a not-set entry plus every value', (tester) async {
    await pump(tester);
    await tester.tap(
      find.byType(DropdownButtonFormField<AndroidMessagePriority?>),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsAtLeast(1));
    expect(find.text('NORMAL'), findsOne);
    expect(find.text('HIGH'), findsOne);
  });

  testWidgets('writes a chosen value back to the input', (tester) async {
    await pump(tester);

    await tester.tap(
      find.byType(DropdownButtonFormField<AndroidMessagePriority?>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('HIGH').last);
    await tester.pumpAndSettle();

    expect(model.priority.value, AndroidMessagePriority.high);
  });

  testWidgets('writes null back when Not set is chosen', (tester) async {
    model.priority.updateValue(AndroidMessagePriority.high);

    await pump(tester);

    await tester.tap(
      find.byType(DropdownButtonFormField<AndroidMessagePriority?>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not set').last);
    await tester.pumpAndSettle();

    expect(model.priority.value, isNull);
  });

  testWidgets('reflects a value set on the input from elsewhere', (
    tester,
  ) async {
    model.priority.updateValue(AndroidMessagePriority.normal);

    await pump(tester);

    expect(
      tester
          .widget<DropdownButtonFormField<AndroidMessagePriority?>>(
            find.byType(DropdownButtonFormField<AndroidMessagePriority?>),
          )
          .initialValue,
      AndroidMessagePriority.normal,
    );
  });
}
