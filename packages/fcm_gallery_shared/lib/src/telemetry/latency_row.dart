import 'package:fcm_gallery_shared/src/json_field.dart';

/// One `sent → received` measurement: a trace, a device, and the two times.
///
/// Here rather than in the API because the app reads the same rows back for its
/// matrix. A row exists only where both halves were recorded — a send with no
/// arrival is absent, not zero.
class LatencyRow {
  /// Normalises both timestamps to UTC, hence not `const`: a local time
  /// serialised without a `Z` is read as the reader's own, inventing hours of
  /// latency.
  LatencyRow({
    required this.traceId,
    required this.deviceId,
    required DateTime sentAt,
    required DateTime receivedAt,
    required this.scenarioId,
  }) : sentAt = sentAt.toUtc(),
       receivedAt = receivedAt.toUtc();

  /// Parses a row as `GET /latency` answers it.
  ///
  /// `latency` is deliberately not read — it is derived, and a carried copy can
  /// disagree.
  factory LatencyRow.fromJson(Map<String, Object?> json) => LatencyRow(
    traceId: requireText(json['trace_id'], 'trace_id'),
    deviceId: requireText(json['device_id'], 'device_id'),
    sentAt: requireTimestamp(json['sent_at'], 'sent_at'),
    receivedAt: requireTimestamp(json['received_at'], 'received_at'),
    scenarioId: _nullableText(json['scenario_id']),
  );

  final String traceId;

  /// Never `''` here: the sending side has no device, and only an arrival makes a
  /// row.
  final String deviceId;

  final DateTime sentAt;

  /// The *first* arrival — duplicate delivery is real FCM behaviour, and
  /// time-to-first is the useful figure.
  final DateTime receivedAt;

  /// Null for a send made by hand, which is a real case rather than an error.
  final String? scenarioId;

  /// Negative when the clocks disagree — see [isSkewed]. Not clamped: that would
  /// turn a measurement error into a false result.
  Duration get latency => receivedAt.difference(sentAt);

  /// Whether the message arrived before it was sent, meaning the device's clock
  /// is behind the server's. Reported, not hidden — a "1ms on Xiaomi" would
  /// discredit every other number in the matrix.
  bool get isSkewed => latency.isNegative;

  /// [latency] is left out on purpose — derived, and a copy on the wire can
  /// disagree.
  Map<String, Object?> toJson() => {
    'trace_id': traceId,
    'device_id': deviceId,
    'sent_at': sentAt.toIso8601String(),
    'received_at': receivedAt.toIso8601String(),
    'scenario_id': ?scenarioId,
  };

  @override
  String toString() =>
      'LatencyRow($traceId $deviceId ${latency.inMilliseconds}ms)';
}

/// Reads an optional string, keeping absence as `null`.
///
/// [readOptionalText] treats absence as `''`, right for a field a validator later
/// reports on, wrong here — see `scenarioId`.
String? _nullableText(Object? value) {
  if (value == null) {
    return null;
  }

  return readOptionalText(value, 'scenario_id');
}
