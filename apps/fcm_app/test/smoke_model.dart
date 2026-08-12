import 'package:glade_forms/glade_forms.dart';

/// A model exercising exactly the three input shapes this plan depends on.
class SmokeModel extends GladeModel {
  late GladeStringInput text;
  late GladeInput<bool?> flag;
  late GladeIntInputNullable count;

  @override
  List<GladeInput<Object?>> get inputs => [text, flag, count];

  @override
  void initialize() {
    text = GladeStringInput(inputKey: 'text', isRequired: false);
    flag = GladeInput<bool?>.optional(inputKey: 'flag', value: null);
    count = GladeIntInputNullable(
      inputKey: 'count',
      useTextEditingController: true,
    );
    super.initialize();
  }
}
