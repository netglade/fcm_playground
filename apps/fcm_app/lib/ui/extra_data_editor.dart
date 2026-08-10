import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import 'data_entry_row.dart';

/// Editor for the extra data keys the payload carries alongside the four the
/// sender writes itself.
///
/// Keeps an ordered list rather than editing the draft's map directly: a map
/// cannot hold a half-typed key, and two blank keys would collapse into one.
/// The map is rebuilt from the list on every change, so the draft only ever
/// sees a well-formed value.
class ExtraDataEditor extends StatefulWidget {
  const ExtraDataEditor({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  State<ExtraDataEditor> createState() => _ExtraDataEditorState();
}

class _ExtraDataEditorState extends State<ExtraDataEditor> {
  late final List<_Entry> _entries = [
    for (final entry in widget.draft.data.entries)
      _Entry(_nextId++, entry.key, entry.value),
  ];
  static int _nextId = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Extra data',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      const SizedBox(height: 8),
      for (final entry in _entries)
        DataEntryRow(
          key: ValueKey(entry.id),
          initialName: entry.name,
          initialValue: entry.value,
          onChanged: (name, value) => _update(entry, name, value),
          onRemove: () => _remove(entry),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add key/value'),
          onPressed: _add,
        ),
      ),
    ],
  );

  void _add() {
    setState(() => _entries.add(_Entry(_nextId++, '', '')));
    _publish();
  }

  void _remove(_Entry entry) {
    setState(() => _entries.remove(entry));
    _publish();
  }

  void _update(_Entry entry, String name, String value) {
    entry
      ..name = name
      ..value = value;
    _publish();
  }

  /// A blank key is dropped rather than reported, so an empty row the user has
  /// just added does not immediately read as an error.
  void _publish() => widget.onChanged(
    widget.draft.copyWith(
      data: {
        for (final entry in _entries)
          if (entry.name.isNotEmpty) entry.name: entry.value,
      },
    ),
  );
}

class _Entry {
  _Entry(this.id, this.name, this.value);

  final int id;
  String name;
  String value;
}
