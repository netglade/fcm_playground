import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// A checkbox for an FCM field that may be true, false, or **absent**.
///
/// FCM treats `direct_boot_ok: false` and an omitted `direct_boot_ok` as
/// different messages, so a two-state checkbox would make "absent" unreachable
/// and silently send fields nobody set. `tristate` is what keeps null a state
/// the user can choose.
class TristateField extends StatelessWidget {
  /// Renders [input] as a tristate checkbox labelled [label].
  const TristateField({required this.label, required this.input, super.key});

  /// The field's name, as FCM spells it.
  final String label;

  /// The bound input; nullable so this widget can represent "not set".
  final GladeInput<bool?> input;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    tristate: true,
    value: input.value,
    title: Text(label),
    subtitle: input.value == null ? const Text('Not sent') : null,
    onChanged: input.updateValue,
  );
}
