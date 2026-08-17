import 'dart:math';

final _random = Random.secure();

/// The number of random bytes appended to the timestamp.
///
/// Eight, so the tail carries 64 bits: the timestamp already separates handsets
/// that were first launched at different microseconds, and this separates the
/// ones that were not.
const _noiseBytes = 8;

/// Mints an identifier for one install, unique across every other install.
///
/// [at] is the instant the identifier is minted, and goes in first so ids sort
/// and read in the order they were created. It is a parameter rather than a
/// `DateTime.now()` inside, because the interesting property — that two
/// handsets first launched in the very same microsecond still get different ids
/// — is only assertable when the caller can hold the instant still.
///
/// Hex and a dash only, because the id travels inside a JSON event body and
/// alongside FCM `data` strings, where anything needing escaping is a
/// liability.
///
/// Deliberately not a UUID library: this value is only ever compared for
/// equality, and a dependency for that would buy nothing.
String newDeviceId(DateTime at) {
  final micros = at.toUtc().microsecondsSinceEpoch;
  final noise = List.generate(
    _noiseBytes,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  return '${micros.toRadixString(16)}-$noise';
}
