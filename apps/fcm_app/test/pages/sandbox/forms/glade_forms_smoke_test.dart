import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import 'smoke_model.dart';

void main() {
  late SmokeModel model;

  // Required once before any GladeModel is created.
  setUpAll(() {
    GladeForms.initialize();
  });

  setUp(() {
    model = SmokeModel()..initialize();
  });

  test('an optional string starts empty and leaves the model valid', () {
    // GladeStringInput defaults isRequired: true, and if that leaked through, ~50
    // FCM fields would each need filling before anything could be sent.
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
      // FINDING, verified against glade_forms 6.0.0:
      // GladeTypeConverters.intConverterNullable treats '' as unparseable rather
      // than as "no value", and the controller-change listener swallows the error
      // without calling _setValue — so the model keeps the last good value instead
      // of resetting to null. This is the default we do NOT want; the
      // converter-backed test below pins the behaviour we depend on.
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
    // GladeStringInput defaults useTextEditingController: true, unlike the int
    // input. Confirming rather than trusting the docs.
    expect(model.text.controller, isNotNull);
  });

  test('the model reports which inputs changed', () {
    model.text.updateValue('hello');

    expect(model.lastUpdatedInputKeys, contains('text'));
  });
}
