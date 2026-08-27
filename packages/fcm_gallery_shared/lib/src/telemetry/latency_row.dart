import 'package:fcm_gallery_shared/src/json_field.dart';

/// One `sent → received` measurement: a trace, a device, and the two times.
///
/// It lives here rather than in the API because the app reads the same rows back to
/// draw its matrix. A row exists only where both halves were recorded — a send with
/// no arrival is absent rather than reported as zero.
class LatencyRow {
  /// Normalises both timestamps to UTC, which is why this is not `const`: a local
  /// time serialised without a `Z` is read as the reader's own, adding hours of
  /// latency out of nowhere.
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
  /// `latency` is deliberately not read: it is derived from the two timestamps, and a
  /// value carried alongside them is one that can disagree.
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

  /// The *first* arrival: a duplicate delivery is real FCM behaviour, and the useful
  /// figure is time-to-first-delivery.
  final DateTime receivedAt;

  /// Null for a send made by hand, which is a real case rather than an error.
  final String? scenarioId;

  /// Negative when the two clocks disagree — see [isSkewed]. Deliberately not
  /// clamped: clamping turns a measurement error into a false result.
  Duration get latency => receivedAt.difference(sentAt);

  /// Whether this row says the message arrived before it was sent, which means the
  /// device's clock is behind the server's. Reported rather than hidden: a "1ms on
  /// Xiaomi" would discredit every other number in the matrix.
  bool get isSkewed => latency.isNegative;

  /// [latency] is left out on purpose: it is derived from the two timestamps, and a
  /// second copy on the wire is one that can disagree with them.
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
/// The shared [readOptionalText] treats absence as `''`, which is right for a field a
/// validator later reports on but wrong here, for the reason `scenarioId` documents.
String? _nullableText(Object? value) {
  if (value == null) {
    return null;
  }

  return readOptionalText(value, 'scenario_id');
}
