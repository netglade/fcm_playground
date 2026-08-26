import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../../i18n/translations.g.dart';

/// A dropdown for an FCM enum field that may be absent.
///
/// Omitting `android.priority` and choosing a value are different messages, so the
/// dropdown carries a `null`-mapped "Not set" entry rather than defaulting to
/// whichever value happens to sort first.
class EnumField<E> extends StatelessWidget {
  const EnumField({
    required this.label,
    required this.input,
    required this.values,
    required this.labelOf,
    super.key,
  });

  final String label;

  /// Nullable so this widget can represent "not set".
  final GladeInput<E?> input;

  final List<E> values;

  /// An enum's `wireName` rather than its Dart member name, so what the user sees
  /// is what goes on the wire.
  final String Function(E) labelOf;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<E?>(
    initialValue: input.value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<E?>(
        value: null,
        child: Text(context.t.form_field.not_set),
      ),
      for (final value in values)
        DropdownMenuItem<E?>(value: value, child: Text(labelOf(value))),
    ],
    onChanged: input.updateValue,
  );
}
