import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// A dropdown for an FCM enum field that may be **absent**.
///
/// FCM's enums are optional the same way its booleans are: omitting
/// `android.priority` and choosing a value are different messages, so the
/// dropdown carries a `null`-mapped "Not set" entry rather than defaulting to
/// whichever value happens to sort first. Labels come from [labelOf] rather
/// than [Enum.name] so the dropdown shows the wire spelling the user is
/// actually setting.
class EnumField<E> extends StatelessWidget {
  /// Renders [input] as a dropdown over [values], labelled [label].
  const EnumField({
    required this.label,
    required this.input,
    required this.values,
    required this.labelOf,
    super.key,
  });

  /// The field's name, as FCM spells it.
  final String label;

  /// The bound input; nullable so this widget can represent "not set".
  final GladeInput<E?> input;

  /// Every value the dropdown offers, besides the built-in "Not set" entry.
  final List<E> values;

  /// How to render a value's text, e.g. an enum's `wireName` rather than its
  /// Dart member name, so what the user sees is what goes on the wire.
  final String Function(E) labelOf;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<E?>(
    initialValue: input.value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<E?>(value: null, child: const Text('Not set')),
      for (final value in values)
        DropdownMenuItem<E?>(value: value, child: Text(labelOf(value))),
    ],
    onChanged: input.updateValue,
  );
}
