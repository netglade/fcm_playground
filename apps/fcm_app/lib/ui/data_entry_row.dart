import 'package:flutter/material.dart';

/// One editable extra-data key/value pair.
///
/// The controllers are owned by `SandboxForm` rather than created here, so
/// removing a row above does not shuffle text between the remaining fields.
class DataEntryRow extends StatelessWidget {
  const DataEntryRow({
    required this.keyController,
    required this.valueController,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  /// Backs the key field. Owned by the parent so it outlives this widget's
  /// rebuilds.
  final TextEditingController keyController;

  /// Backs the value field. Owned by the parent so it outlives this widget's
  /// rebuilds.
  final TextEditingController valueController;

  /// Called on every keystroke, so validation keeps up with the form.
  final VoidCallback onChanged;

  /// Called when this row should be dropped from the form.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: keyController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'key'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: valueController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'value'),
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: 'Remove this key',
        ),
      ],
    ),
  );
}
