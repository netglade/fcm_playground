import 'package:fcm_app/pages/sandbox/widgets/form/tristate_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../../helpers/pump_app.dart';
import 'tristate_field_model.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late TristateFieldModel model;

  setUp(() {
    model = TristateFieldModel()..initialize();
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    TristateField(label: 'Direct boot ok', input: model.flag),
  );

  testWidgets('starts unset, which is not the same as false', (tester) async {
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isNull);
    expect(model.flag.value, isNull);
  });

  testWidgets('is tristate, so absent stays reachable', (tester) async {
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).tristate, isTrue);
  });

  testWidgets('shows its label, since a bare checkbox says nothing', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Direct boot ok'), findsOne);
  });

  testWidgets('writes each of the three states back to the input', (
    tester,
  ) async {
    await pump(tester);

    // TristateField has no listener of its own: an app rebuilds it when the bound
    // GladeModel fires, which re-pumping stands in for. Without that, the checkbox's
    // `value` never advances past its first build.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final first = model.flag.value;

    await pump(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final second = model.flag.value;

    await pump(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final third = model.flag.value;

    // Whatever order Flutter cycles them in, all three must be visited.
    expect({first, second, third}, {null, true, false});
  });

  testWidgets('reflects a value set on the input from elsewhere', (
    tester,
  ) async {
    model.flag.updateValue(true);

    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
