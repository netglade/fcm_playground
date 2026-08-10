import 'package:flutter/material.dart';

/// One editable extra data key/value pair.
///
/// Holds its own controllers so the parent can rebuild freely without the text
/// jumping. Reports both halves on every keystroke, because a key without its
/// value is not a meaningful intermediate state to the draft.
class DataEntryRow extends StatefulWidget {
  const DataEntryRow({
    required this.initialName,
    required this.initialValue,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final String initialName;
  final String initialValue;
  final void Function(String name, String value) onChanged;
  final VoidCallback onRemove;

  @override
  State<DataEntryRow> createState() => _DataEntryRowState();
}

class _DataEntryRowState extends State<DataEntryRow> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _value = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Key'),
            onChanged: (_) => _report(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _value,
            decoration: const InputDecoration(labelText: 'Value'),
            onChanged: (_) => _report(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Remove',
          onPressed: widget.onRemove,
        ),
      ],
    ),
  );

  void _report() => widget.onChanged(_name.text, _value.text);
}
