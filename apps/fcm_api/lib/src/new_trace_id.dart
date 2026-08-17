import 'dart:math';

final _random = Random.secure();

/// Mints an id for one send, unique across this server and every other.
///
/// A microsecond timestamp so ids read in the order they were made, plus 32 random
/// bits so two sends in the same microsecond cannot collide. Hex and a dash only,
/// because the id travels as an FCM `data` string and comes back in a JSON body.
String newTraceId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  final noise = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');

  return '${micros.toRadixString(16)}-$noise';
}
