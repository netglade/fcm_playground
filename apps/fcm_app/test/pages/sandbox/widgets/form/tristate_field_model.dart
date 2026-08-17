import 'package:glade_forms/glade_forms.dart';

/// Binds a single nullable-bool input for `tristate_field_test.dart`.
///
/// Its own file because `prefer-match-file-name` fires on any top-level class
/// declared inside a `_test.dart` file — see `test/smoke_model.dart` for the
/// same convention.
class TristateFieldModel extends GladeModel {
  /// The field under test; starts absent, exactly like an unset FCM bool.
  late GladeInput<bool?> flag;

  @override
  List<GladeInput<Object?>> get inputs => [flag];

  @override
  void initialize() {
    flag = GladeInput<bool?>.optional(inputKey: 'flag', value: null);
    super.initialize();
  }
}
