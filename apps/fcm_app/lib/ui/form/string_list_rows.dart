import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Edits a `List<String>` as one row per item.
///
/// The row count is not known ahead of time, so there is no fixed
/// [TextEditingController] to bind — this widget owns its rows' controllers as
/// view state and reports the collapsed list through [onChanged] on every
/// keystroke, the same way the map-row editor does for key/value pairs.
class StringListRows extends StatefulWidget {
  /// Renders [value] as rows labelled [label], reporting edits to [onChanged].
  const StringListRows({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The heading shown above the rows.
  final String label;

  /// The items this widget displays. Changes are reloaded into the rows when
  /// the value differs from what the rows would collapse to, enabling the rows
  /// to update from external changes while preventing rewinding during a user's
  /// own edits.
  final List<String> value;

  /// Called with the current list whenever a row is added, edited, or removed.
  final ValueChanged<List<String>> onChanged;

  @override
  State<StringListRows> createState() => _StringListRowsState();
}

class _StringListRowsState extends State<StringListRows> {
  late List<TextEditingController> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [];
    _reload();
  }

  @override
  void didUpdateWidget(StringListRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload only when the value arrived from outside — after the user's own
    // keystroke the parent rebuilds us with exactly what we just reported, so
    // comparing against our own output is what stops the cursor jumping.
    if (!listEquals(widget.value, _collapsed())) {
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
  Widget build(BuildContext context) => Column(
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
                child: TextField(controller: row, onChanged: (_) => _push()),
              ),
              IconButton(
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove this row',
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: _addRow, child: const Text('Add')),
      ),
    ],
  );

  void _addRow() {
    setState(() => _rows.add(TextEditingController()));
    _push();
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _push();
  }

  /// Rebuilds the rows from [widget.value], disposing the existing controllers.
  void _reload() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows = [
      for (final item in widget.value) TextEditingController(text: item),
    ];
  }

  /// Returns the list that the current rows collapse to, dropping any row that
  /// is blank so a half-typed row never produces an empty entry.
  List<String> _collapsed() => [
    for (final row in _rows)
      if (row.text.trim().isNotEmpty) row.text,
  ];

  /// Reports the rows as a list through [onChanged].
  void _push() => widget.onChanged(_collapsed());
}
