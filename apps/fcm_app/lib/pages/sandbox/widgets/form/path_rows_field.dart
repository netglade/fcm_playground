import 'package:flutter/material.dart';

import '../../forms/path_rows.dart';
import 'string_map_rows.dart';

/// Edits a free-form nested payload as dotted-path rows.
///
/// `apns.payload` and `webpush.notification` are free-form JSON, so there is no
/// fixed set of fields to bind. This delegates to [StringMapRows] and lets
/// [flattenPaths]/[expandPaths] do the nesting a plain map editor could not.
class PathRowsField extends StatelessWidget {
  const PathRowsField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;

  final Map<String, Object?> value;

  final ValueChanged<Map<String, Object?>> onChanged;

  @override
  Widget build(BuildContext context) => StringMapRows(
    label: label,
    value: {for (final row in flattenPaths(value)) row.key: row.value},
    onChanged: (rows) => onChanged(expandPaths(rows.entries.toList())),
  );
}
