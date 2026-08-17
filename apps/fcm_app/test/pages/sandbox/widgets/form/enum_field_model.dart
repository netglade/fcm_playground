import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

/// Binds a single nullable-enum input for `enum_field_test.dart`.
///
/// Its own file because `prefer-match-file-name` fires on any top-level class
/// declared inside a `_test.dart` file.
class EnumFieldModel extends GladeModel {
  /// The field under test; starts absent, exactly like an unset FCM enum.
  late GladeInput<AndroidMessagePriority?> priority;

  @override
  List<GladeInput<Object?>> get inputs => [priority];

  @override
  void initialize() {
    priority = GladeInput<AndroidMessagePriority?>.optional(
      inputKey: 'priority',
      value: null,
    );
    super.initialize();
  }
}
