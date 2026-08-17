import 'dart:math';

final _random = Random.secure();

const _noiseBytes = 8;

/// Mints an identifier for one install, unique across every other install.
///
/// [at] goes in first so ids sort in the order they were created. It is a parameter
/// rather than a `DateTime.now()` inside, because the interesting property — two
/// handsets first launched in the same microsecond still get different ids — is
/// only assertable when the caller can hold the instant still.
///
/// Hex and a dash only, because the id travels inside a JSON event body and
/// alongside FCM `data` strings.
String newDeviceId(DateTime at) {
  final micros = at.toUtc().microsecondsSinceEpoch;
  final noise = List.generate(
    _noiseBytes,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  return '${micros.toRadixString(16)}-$noise';
}
