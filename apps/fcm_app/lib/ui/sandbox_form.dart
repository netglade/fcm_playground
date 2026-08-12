import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'data_entry_row.dart';

/// The editable payload: title, body, and the extra data rows.
///
/// It owns the [TextEditingController]s, because those are view state and the
/// controller must stay testable without a widget pump. Loading a preset changes
/// [SandboxController.scenarioRevision], and the parent keys this widget on that
/// revision — so a preset replaces the fields by replacing this `State`, while
/// ordinary typing never disturbs the cursor.
class SandboxForm extends StatefulWidget {
  const SandboxForm({required this.controller, super.key});

  /// The controller this form reads its initial values from and pushes edits
  /// into.
  final SandboxController controller;

  @override
  State<SandboxForm> createState() => _SandboxFormState();
}

class _SandboxFormState extends State<SandboxForm> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final List<_DataRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.controller.title);
    _body = TextEditingController(text: widget.controller.body);
    _rows = widget.controller.entries.map(_DataRowControllers.of).toList();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _title,
        onChanged: (_) => _push(),
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _problemWith('title'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _body,
        onChanged: (_) => _push(),
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Body',
          errorText: _problemWith('body'),
        ),
      ),
      const SizedBox(height: 20),
      Text('Extra data', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final (index, row) in _rows.indexed)
        DataEntryRow(
          keyController: row.key,
          valueController: row.value,
          onChanged: _push,
          onRemove: () => _removeRow(index),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addRow,
          icon: const Icon(Icons.add),
          label: const Text('Add key/value'),
        ),
      ),
      for (final problem in widget.controller.problems)
        if (problem.field.startsWith('data'))
          Text(
            '$problem',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
    ],
  );

  /// The message for [field], or null when it is fine.
  String? _problemWith(String field) {
    for (final problem in widget.controller.problems) {
      if (problem.field == field) {
        return problem.message;
      }
    }

    return null;
  }

  /// Pushes the whole form into the controller, which revalidates.
  ///
  /// The rows go up as a list, not a map, so a key typed twice is reported
  /// instead of one value silently winning.
  void _push() => widget.controller.edit(
    title: _title.text,
    body: _body.text,
    entries: [for (final row in _rows) MapEntry(row.key.text, row.value.text)],
  );

  void _addRow() {
    setState(() => _rows.add(_DataRowControllers.empty()));
    _push();
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _push();
  }
}

/// The two controllers behind one data row.
class _DataRowControllers {
  _DataRowControllers({required this.key, required this.value});

  factory _DataRowControllers.of(MapEntry<String, String> entry) =>
      _DataRowControllers(
        key: TextEditingController(text: entry.key),
        value: TextEditingController(text: entry.value),
      );

  factory _DataRowControllers.empty() => _DataRowControllers(
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
