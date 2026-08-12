import 'package:flutter/material.dart';

import '../../sandbox/forms/path_rows.dart';
import 'string_map_rows.dart';

/// Edits a free-form nested payload as dotted-path rows.
///
/// `apns.payload` and `webpush.notification` are free-form JSON by FCM's own
/// definition, so there is no fixed set of fields to bind. This delegates to
/// [StringMapRows] — the same row-holding, controller-disposing widget any map
/// is edited with — and lets [flattenPaths]/[expandPaths] do the nesting a
/// plain map editor could not.
class PathRowsField extends StatelessWidget {
  /// Renders [value]'s leaves as dotted-path rows labelled [label].
  const PathRowsField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The heading shown above the rows.
  final String label;

  /// The nested payload this field starts with. Flattened once per build into
  /// the rows [StringMapRows] shows.
  final Map<String, Object?> value;

  /// Called with the nested payload rebuilt from the current rows.
  final ValueChanged<Map<String, Object?>> onChanged;

  @override
  Widget build(BuildContext context) => StringMapRows(
    label: label,
    value: {for (final row in flattenPaths(value)) row.key: row.value},
    onChanged: (rows) => onChanged(expandPaths(rows.entries.toList())),
  );
}
