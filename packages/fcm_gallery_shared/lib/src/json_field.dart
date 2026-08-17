/// JSON field readers shared by the DTOs in this package.
///
/// They exist so a malformed body fails as a [FormatException] naming the
/// offending field, rather than as a `TypeError` from a blind cast that says
/// nothing a caller could act on.
library;

/// Absence becomes `''`, and blankness is deliberately not an error: the validator
/// reports it against the field, which produces a message a user can read, whereas a
/// parse failure would only produce a generic 400.
String readOptionalText(Object? value, String field) {
  if (value == null) {
    return '';
  }
  if (value is! String) {
    throw FormatException(
      '"$field" must be a string, got ${value.runtimeType}',
    );
  }

  return value;
}

String requireText(Object? value, String field) {
  if (value == null) {
    throw FormatException('"$field" is missing');
  }

  return readOptionalText(value, field);
}

/// Normalised to UTC.
DateTime requireTimestamp(Object? value, String field) {
  final raw = requireText(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('"$field" must be an ISO-8601 timestamp, got "$raw"');
  }

  return parsed.toUtc();
}

Map<String, String> readStringMap(Object? value, String field) {
  if (value == null) {
    return const {};
  }
  if (value is! Map<String, Object?>) {
    throw FormatException(
      '"$field" must be an object, got ${value.runtimeType}',
    );
  }

  final result = <String, String>{};
  for (final entry in value.entries) {
    result[entry.key] = readOptionalText(entry.value, '$field["${entry.key}"]');
  }

  return Map.unmodifiable(result);
}

/// Missing is an error, non-integer is an error.
int requireInt(Object? value, String field) {
  if (value == null) {
    throw FormatException('"$field" is missing');
  }
  if (value is! int) {
    throw FormatException(
      '"$field" must be an integer, got ${value.runtimeType}',
    );
  }

  return value;
}

/// Missing is an error, non-object is an error.
Map<String, Object?> requireObject(Object? value, String field) {
  if (value == null) {
    throw FormatException('"$field" is missing');
  }
  if (value is! Map<String, Object?>) {
    throw FormatException(
      '"$field" must be an object, got ${value.runtimeType}',
    );
  }

  return value;
}
