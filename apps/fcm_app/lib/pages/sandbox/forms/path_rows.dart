/// Expands dotted-path rows into the nested structure FCM and Apple expect.
///
/// `apns.payload` and `webpush.notification` are free-form by FCM's own
/// definition, so they are edited as rows rather than as fields. A path builds
/// the nesting: `aps.alert.title` becomes
/// `{'aps': {'alert': {'title': …}}}`.
///
/// A **numeric** segment builds a list rather than a map, because Apple's
/// `loc-args` and `title-loc-args` are string arrays — without this they would
/// round-trip into the literal text `[a, b]`.
///
/// A blank path is dropped, so a half-typed row never produces an empty key.
Map<String, Object?> expandPaths(List<MapEntry<String, String>> rows) {
  final result = <String, Object?>{};

  for (final row in rows) {
    final segments = row.key.trim().split('.');
    if (segments.any((segment) => segment.isEmpty)) {
      continue;
    }
    _place(result, segments, _scalarOf(row.value));
  }

  return result;
}

/// Flattens a nested structure back into the rows the editor shows, so a
/// scenario's payload arrives as something editable and leaves unchanged.
List<MapEntry<String, String>> flattenPaths(Map<String, Object?> source) {
  final rows = <MapEntry<String, String>>[];
  _walk('', source, rows);

  return rows;
}

/// Reads a row's text as the JSON scalar it looks like.
///
/// `badge` is a number and `content-available` is 0 or 1, so treating every value
/// as text would produce payloads APNs rejects or misreads. Decimals stay text —
/// Apple does not use them here and they would lose their exact form.
Object? _scalarOf(String value) => switch (value) {
  'true' => true,
  'false' => false,
  _ => int.tryParse(value) ?? value,
};

bool _isIndex(String segment) => int.tryParse(segment) != null;

void _place(Map<String, Object?> root, List<String> segments, Object? value) {
  Object? node = root;

  for (var index = 0; index < segments.length - 1; index++) {
    node = _childOf(node, segments[index], _isIndex(segments[index + 1]));
  }

  _set(node, segments.last, value);
}

/// Returns the container at [segment], creating it when absent. [nextIsIndex] is
/// the only place the numeric-segment rule takes effect.
Object? _childOf(Object? node, String segment, bool nextIsIndex) {
  final existing = _get(node, segment);
  if (existing is Map<String, Object?> || existing is List<Object?>) {
    return existing;
  }

  final child = nextIsIndex ? <Object?>[] : <String, Object?>{};
  _set(node, segment, child);

  return child;
}

Object? _get(Object? node, String segment) => switch (node) {
  final Map<String, Object?> map => map[segment],
  final List<Object?> list =>
    _isIndex(segment) && int.parse(segment) < list.length
        ? list[int.parse(segment)]
        : null,
  _ => null,
};

void _set(Object? node, String segment, Object? value) {
  if (node is Map<String, Object?>) {
    node[segment] = value;

    return;
  }
  if (node is List<Object?> && _isIndex(segment)) {
    final index = int.parse(segment);
    while (node.length <= index) {
      node.add(null);
    }
    node[index] = value;
  }
}

void _walk(String prefix, Object? node, List<MapEntry<String, String>> rows) {
  switch (node) {
    case final Map<String, Object?> map:
      for (final entry in map.entries) {
        _walk(_join(prefix, entry.key), entry.value, rows);
      }
    case final List<Object?> list:
      for (final (index, item) in list.indexed) {
        _walk(_join(prefix, '$index'), item, rows);
      }
    default:
      rows.add(MapEntry(prefix, '$node'));
  }
}

String _join(String prefix, String segment) =>
    prefix.isEmpty ? segment : '$prefix.$segment';
