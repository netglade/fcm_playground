/// Finds every delivery-target key anywhere inside a payload template.
///
/// The top level is already protected — `FcmMessage.read` rejects `token`, `topic`
/// and `condition` there — but a nested `data: {'topic': 'news'}` is a legal
/// string-map entry and anything under `apns.payload` is forwarded verbatim, so this
/// walks maps and lists to any depth.
///
/// [path] prefixes what is reported, so a hit names *where* it is rather than only
/// that there is one.
library;

Iterable<String> targetKeysIn(Object? node, String path) {
  const targetKeys = ['token', 'topic', 'condition'];
  final found = <String>[];

  if (node is Map) {
    for (final entry in node.entries) {
      final here = '$path/${entry.key}';
      if (targetKeys.contains(entry.key)) {
        found.add(here);
      }
      found.addAll(targetKeysIn(entry.value, here));
    }
  } else if (node is List) {
    for (final (index, item) in node.indexed) {
      found.addAll(targetKeysIn(item, '$path[$index]'));
    }
  }

  return found;
}
