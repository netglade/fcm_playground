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
