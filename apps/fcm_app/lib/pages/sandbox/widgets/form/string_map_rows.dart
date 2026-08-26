import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/translations.g.dart';

/// Edits a `Map<String, String>` as one key/value row per entry.
///
/// The row count is not known ahead of time, so there is no fixed
/// [TextEditingController] to bind — this widget owns its rows' controllers as view
/// state and reports the collapsed map through [onChanged] on every keystroke.
class StringMapRows extends StatefulWidget {
  const StringMapRows({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;

  final Map<String, String> value;

  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<StringMapRows> createState() => _StringMapRowsState();
}

class _StringMapRowsState extends State<StringMapRows> {
  late List<_MapRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [];
    _reload();
  }

  @override
  void didUpdateWidget(StringMapRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload only when the value arrived from outside — after the user's own
    // keystroke the parent rebuilds us with exactly what we just reported, so
    // comparing against our own output is what stops the cursor jumping.
    if (!mapEquals(widget.value, _collapsed())) {
      _reload();
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final (index, row) in _rows.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.key,
                    onChanged: (_) => _push(),
                    decoration: const InputDecoration(labelText: 'key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.value,
                    onChanged: (_) => _push(),
                    decoration: const InputDecoration(labelText: 'value'),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeRow(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: t.form_field.remove_row,
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _addRow,
            child: Text(t.form_field.add_row),
          ),
        ),
      ],
    );
  }

  void _addRow() {
    setState(() => _rows.add(_MapRowControllers.empty()));
    _push();
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _push();
  }

  void _reload() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows = [
      for (final entry in widget.value.entries) _MapRowControllers.of(entry),
    ];
  }

  /// Drops any row whose key is blank, so a half-typed row never produces an
  /// empty key.
  Map<String, String> _collapsed() => {
    for (final row in _rows)
      if (row.key.text.trim().isNotEmpty) row.key.text: row.value.text,
  };

  void _push() => widget.onChanged(_collapsed());
}

class _MapRowControllers {
  _MapRowControllers({required this.key, required this.value});

  factory _MapRowControllers.of(MapEntry<String, String> entry) =>
      _MapRowControllers(
        key: TextEditingController(text: entry.key),
        value: TextEditingController(text: entry.value),
      );

  factory _MapRowControllers.empty() => _MapRowControllers(
    key: TextEditingController(),
    value: TextEditingController(),
  );

  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}
