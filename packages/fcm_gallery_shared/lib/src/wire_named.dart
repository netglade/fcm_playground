/// A value that travels under a name of its own, independent of its Dart
/// identifier.
///
/// Implemented by every enum in this package that crosses the wire, so renaming
/// an enum value cannot silently change the payload a deployed sender produces.
abstract interface class WireNamed {
  /// The value that goes on the wire.
  String get wireName;
}

/// The element of [values] whose [WireNamed.wireName] is [wireName], or `null`
/// when nothing matches.
///
/// Returns `null` rather than throwing: a payload from an older or newer sender
/// must not be able to break the receiver.
T? wireNamedFrom<T extends WireNamed>(Iterable<T> values, String wireName) {
  for (final value in values) {
    if (value.wireName == wireName) {
      return value;
    }
  }

  return null;
}
