/// Reads a JSON object strictly: every key must be claimed by a read, and
/// anything left over is an error.
///
/// Rejecting unknown fields is only useful if the error says *where*, so the
/// reader carries the path it is reading and composes it for nested objects —
/// producing `message.android.notification: unknown field "titel"` rather than a
/// bare complaint. That message is the whole point of parsing strictly.
class JsonObjectReader {
  JsonObjectReader(this._json, {required this._path});

  /// Reads [value] as an object, or throws [FormatException] naming [path].
  ///
  /// Used for nested objects, where the value's type is not yet known.
  factory JsonObjectReader.of(Object? value, {required String path}) {
    if (value is! Map<String, Object?>) {
      throw FormatException('$path: expected an object, got ${_nameOf(value)}');
    }

    return JsonObjectReader(value, path: path);
  }

  final Map<String, Object?> _json;
  final String _path;
  final _claimed = <String>{};

  /// An optional string.
  String? text(String key) =>
      _read(key, 'a string', (value) => value is String ? value : null);

  /// An optional boolean. A present `false` is a value, not an absence.
  bool? flag(String key) =>
      _read(key, 'a boolean', (value) => value is bool ? value : null);

  /// An optional integer. A present `0` is a value, not an absence.
  int? integer(String key) =>
      _read(key, 'an integer', (value) => value is int ? value : null);

  /// An optional number. An `int` is accepted, since JSON does not distinguish
  /// `1` from `1.0` and FCM's colour components are written both ways.
  double? number(String key) => _read(key, 'a number', (value) {
    if (value is double) {
      return value;
    }

    return value is int ? value.toDouble() : null;
  });

  /// An optional list of strings.
  List<String>? textList(String key) =>
      _read(key, 'a list of strings', (value) {
        if (value is! List<Object?>) {
          return null;
        }

        final items = <String>[];
        for (final item in value) {
          if (item is! String) {
            return null;
          }
          items.add(item);
        }

        return List.unmodifiable(items);
      });

  /// An optional object of string values, whose keys are the caller's own.
  Map<String, String>? stringMap(String key) =>
      _read(key, 'an object of strings', (value) {
        if (value is! Map<String, Object?>) {
          return null;
        }

        final entries = <String, String>{};
        for (final entry in value.entries) {
          final entryValue = entry.value;
          if (entryValue is! String) {
            return null;
          }
          entries[entry.key] = entryValue;
        }

        return Map.unmodifiable(entries);
      });

  /// An optional object passed through without inspection.
  ///
  /// For the fields FCM itself defines as free-form — `apns.payload`,
  /// `webpush.notification` — where an unknown key is the caller's business and
  /// rejecting it would be wrong.
  Map<String, Object?>? freeForm(String key) => _read(
    key,
    'an object',
    (value) => value is Map<String, Object?> ? Map.unmodifiable(value) : null,
  );

  /// An optional nested object, parsed by [parse] with the composed path.
  T? object<T>(String key, T Function(JsonObjectReader reader) parse) {
    _claimed.add(key);
    final value = _json[key];
    if (value == null) {
      return null;
    }

    return parse(JsonObjectReader.of(value, path: '$_path.$key'));
  }

  /// An optional enum, matched against [values] by wire name.
  ///
  /// An unrecognised value throws rather than returning null: it is
  /// indistinguishable from a typo, and silently dropping it would send
  /// something other than what was written.
  E? enumValue<E>(
    String key,
    List<E> values,
    String Function(E value) wireNameOf,
  ) {
    final raw = text(key);
    if (raw == null) {
      return null;
    }

    for (final value in values) {
      if (wireNameOf(value) == raw) {
        return value;
      }
    }

    throw FormatException('$_path.$key: unknown value "$raw"');
  }

  /// Throws [FormatException] naming every key no read claimed.
  void requireNothingUnclaimed() {
    final unknown = _json.keys.where((key) => !_claimed.contains(key)).toList();
    if (unknown.isEmpty) {
      return;
    }

    final names = unknown.map((key) => '"$key"').join(', ');
    final label = unknown.length == 1 ? 'unknown field' : 'unknown fields';

    throw FormatException('$_path: $label $names');
  }

  T? _read<T>(String key, String expected, T? Function(Object? value) convert) {
    _claimed.add(key);
    final value = _json[key];
    if (value == null) {
      return null;
    }

    final converted = convert(value);
    if (converted == null) {
      throw FormatException(
        '$_path.$key: expected $expected, got ${_nameOf(value)}',
      );
    }

    return converted;
  }
}

/// A readable type name for an error message, since `runtimeType` on a decoded
/// map reads as `_Map<String, dynamic>` and helps nobody.
String _nameOf(Object? value) => switch (value) {
  null => 'null',
  String() => 'a string',
  bool() => 'a boolean',
  int() => 'an integer',
  double() => 'a number',
  List<Object?>() => 'a list',
  Map<String, Object?>() => 'an object',
  _ => '${value.runtimeType}',
};
