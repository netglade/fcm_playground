/// Finds every delivery-target key anywhere inside a payload template.
///
/// `payloadTemplate.containsKey('topic')` only sees the top level, and the top
/// level is the one place already protected — `FcmMessage.read` rejects `token`,
/// `topic` and `condition` there outright. A *nested* target slips past both:
/// `data: {'topic': 'news'}` is a legal `map<string, string>` entry, and anything
/// under `apns.payload` is forwarded to Apple verbatim, so the typed model has no
/// opinion about either. This walks maps and lists to any depth instead.
///
/// [path] prefixes what is reported, so a hit names *where* it is rather than
/// only that there is one — which is the difference between a usable failure and
/// a hunt through 66 templates.
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
