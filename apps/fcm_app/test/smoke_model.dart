import 'package:glade_forms/glade_forms.dart';

/// A model exercising exactly the three input shapes this plan depends on,
/// plus [convertedCount], which pins the converter Task 8 relies on to make
/// clearing an optional int field mean "absent" rather than "keep the old
/// value" (see `count`'s documented-defect test in the smoke test file).
class SmokeModel extends GladeModel {
  late GladeStringInput text;
  late GladeInput<bool?> flag;
  late GladeIntInputNullable count;
  late GladeIntInputNullable convertedCount;

  @override
  List<GladeInput<Object?>> get inputs => [text, flag, count, convertedCount];

  @override
  void initialize() {
    text = GladeStringInput(inputKey: 'text', isRequired: false);
    flag = GladeInput<bool?>.optional(inputKey: 'flag', value: null);
    count = GladeIntInputNullable(
      inputKey: 'count',
      useTextEditingController: true,
    );
    convertedCount = GladeIntInputNullable(
      inputKey: 'convertedCount',
      useTextEditingController: true,
      stringToValueConverter: StringToTypeConverter<int?>(
        converter: (raw, _) =>
            (raw == null || raw.trim().isEmpty) ? null : int.parse(raw),
        converterBack: (value) => value?.toString() ?? '',
      ),
    );
    super.initialize();
  }
}
