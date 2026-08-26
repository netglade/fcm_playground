import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../../i18n/translations.g.dart';

/// A checkbox for an FCM field that may be true, false, or absent.
///
/// FCM treats `direct_boot_ok: false` and an omitted `direct_boot_ok` as different
/// messages, so a two-state checkbox would make "absent" unreachable and silently
/// send fields nobody set.
class TristateField extends StatelessWidget {
  const TristateField({required this.label, required this.input, super.key});

  final String label;

  /// Nullable so this widget can represent "not set".
  final GladeInput<bool?> input;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    tristate: true,
    value: input.value,
    title: Text(label),
    subtitle: input.value == null ? Text(context.t.form_field.not_sent) : null,
    onChanged: input.updateValue,
  );
}
