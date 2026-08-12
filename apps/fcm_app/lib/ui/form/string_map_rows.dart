import 'package:flutter/material.dart';

/// Edits a `Map<String, String>` as one key/value row per entry.
///
/// The row count is not known ahead of time, so there is no fixed
/// [TextEditingController] to bind — this widget owns its rows' controllers as
/// view state and reports the collapsed map through [onChanged] on every
/// keystroke, the same way the deleted `SandboxForm` handled its data rows.
class StringMapRows extends StatefulWidget {
  /// Renders [value] as rows labelled [label], reporting edits to [onChanged].
  const StringMapRows({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The heading shown above the rows.
  final String label;

  /// The entries this widget starts with. Read once, in [State.initState] —
  /// later changes flow out through [onChanged], not back in, so typing never
  /// fights a value pushed from elsewhere.
  final Map<String, String> value;

  /// Called with the current map whenever a row is added, edited, or removed.
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<StringMapRows> createState() => _StringMapRowsState();
}

class _StringMapRowsState extends State<StringMapRows> {
  late final List<_MapRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final entry in widget.value.entries) _MapRowControllers.of(entry),
    ];
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
    setState(() => _rows.add(_MapRowControllers.empty()));
    _push();
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _push();
  }

  /// Reports the rows as a map, dropping any row whose key is blank so a
  /// half-typed row never produces an empty key.
  void _push() => widget.onChanged({
    for (final row in _rows)
      if (row.key.text.trim().isNotEmpty) row.key.text: row.value.text,
  });
}

/// The two controllers behind one key/value row.
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
