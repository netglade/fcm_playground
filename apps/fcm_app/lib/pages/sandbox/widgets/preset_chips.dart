import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';

/// A row of choice chips for picking one of [values], in seconds.
///
/// Its own widget rather than a method returning a `Widget`: `avoid-returning-
/// widgets` is fatal here, and the app has no `Widget _helper()` methods anywhere.
class PresetChips extends StatelessWidget {
  const PresetChips({
    required this.values,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<int> values;

  final int selected;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Wrap(
      spacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(t.preset_chip.seconds(value: value)),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
