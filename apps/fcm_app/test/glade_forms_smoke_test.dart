import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'smoke_model.dart';

void main() {
  late SmokeModel model;

  // glade_forms requires this once before any GladeModel is created; it
  // wires up its DevTools inspector and is unrelated to the three
  // assumptions this smoke test exists to check.
  setUpAll(() {
    GladeForms.initialize();
  });

  setUp(() {
    model = SmokeModel()..initialize();
  });

  test('an optional string starts empty and leaves the model valid', () {
    // GladeStringInput defaults isRequired: true. If that default leaked
    // through, the model would be invalid here and ~50 FCM fields would each
    // need to be filled before anything could be sent.
    expect(model.text.value, isEmpty);
    expect(model.isValid, isTrue);
  });

  test('a nullable bool really holds three distinct states', () {
    // The whole tristate design rests on this. GladeBoolInput is
    // GladeInput<bool> and cannot do it.
    expect(model.flag.value, isNull);

    model.flag.updateValue(true);
    expect(model.flag.value, isTrue);

    model.flag.updateValue(false);
    expect(model.flag.value, isFalse);

    model.flag.updateValue(null);
    expect(model.flag.value, isNull);
  });

  test('a nullable int exposes a controller when asked for one', () {
    expect(model.count.controller, isNotNull);
    expect(model.count.value, isNull);
  });

  test('a nullable int reads back a typed value from its controller', () {
    model.count.controller!.text = '42';

    expect(model.count.value, 42);
  });

  test(
    'the default int converter keeps the old value when cleared (documented defect)',
    () async {
      // FINDING (not the documented microtask wrinkle — confirmed present
      // even after an extra event-loop turn below): GladeTypeConverters
      // .intConverterNullable treats '' as an unparseable value, not as "no
      // value" (it calls cantConvert(), which throws ConvertError). The
      // controller-change listener swallows that error without calling
      // _setValue, so the model silently keeps the last good value instead
      // of resetting to null. Asserted here as the actual, verified
      // behaviour of glade_forms 6.0.0 — see task-1-report.md. This is the
      // default we do NOT want; see the converter-backed test below for the
      // behaviour Task 8 actually depends on.
      model.count.controller!.text = '42';
      model.count.controller!.text = '';

      await Future<void>.delayed(Duration.zero);

      expect(model.count.value, 42);
    },
  );

  test('with a converter, clearing the int field means absent', () async {
    // Task 8's notification_count depends on this: without the converter,
    // clearing the field silently keeps the old number and sends it.
    model.convertedCount.controller!.text = '42';
    await Future<void>.delayed(Duration.zero);
    expect(model.convertedCount.value, 42);

    model.convertedCount.controller!.text = '';
    await Future<void>.delayed(Duration.zero);

    expect(model.convertedCount.value, isNull);
    expect(model.isValid, isTrue);
  });

  test('a string input exposes a controller by default', () {
    // GladeStringInput defaults useTextEditingController: true, unlike the
    // int input. Confirming rather than trusting the docs.
    expect(model.text.controller, isNotNull);
  });

  test('the model reports which inputs changed', () {
    model.text.updateValue('hello');

    expect(model.lastUpdatedInputKeys, contains('text'));
  });
}
