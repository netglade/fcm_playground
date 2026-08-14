/// One `sent → received` measurement: a trace, a device, and the two times.
///
/// The one number this pipeline exists to produce, and the row `GET /latency`
/// returns. It lives here rather than in the API because the app reads the same
/// rows back to draw its matrix, and two spellings of one wire format would
/// diverge.
///
/// A row exists only where both halves were recorded: a send with no arrival is
/// **absent** rather than reported as zero, because not-delivered and
/// delivered-instantly are different states.
class LatencyRow {
  /// Creates a row, normalising both timestamps to UTC.
  ///
  /// The normalisation is why this constructor is not `const`, and it is the
  /// same reason `TelemetryEvent` gives: a local time serialised without a `Z`
  /// is read as the reader's own local time, which adds hours of latency out of
  /// nowhere and reads as a delivery fault.
  LatencyRow({
    required this.traceId,
    required this.deviceId,
    required DateTime sentAt,
    required DateTime receivedAt,
    required this.scenarioId,
  }) : sentAt = sentAt.toUtc(),
       receivedAt = receivedAt.toUtc();

  /// The send this measures, as minted by the API.
  final String traceId;

  /// The install that reported the arrival. Never `''` here: the sending side
  /// has no device, and only an arrival makes a row.
  final String deviceId;

  /// When the API handed the message to FCM, in UTC.
  final DateTime sentAt;

  /// When the device first reported it, in UTC.
  ///
  /// The *first* arrival: a duplicate delivery is real FCM behaviour, and the
  /// useful figure is time-to-first-delivery.
  final DateTime receivedAt;

  /// The scenario behind the send, when either side knew it.
  ///
  /// Null for a send made by hand, which is a real case rather than an error —
  /// so it is nullable rather than defaulted to something that would group with
  /// the gallery's own rows.
  final String? scenarioId;

  /// How long the message took to arrive.
  ///
  /// Negative when the two clocks disagree — see [isSkewed]. Deliberately not
  /// clamped: clamping turns a measurement error into a false result.
  Duration get latency => receivedAt.difference(sentAt);

  /// Whether this row says the message arrived before it was sent.
  ///
  /// That is impossible, so it means the device's clock is behind the server's,
  /// and the row is evidence of skew rather than of a fast delivery. Reported
  /// rather than hidden: a "1ms on Xiaomi" would discredit every other number
  /// in the matrix.
  bool get isSkewed => latency.isNegative;

  /// Serialises the row, omitting an unknown scenario rather than writing null,
  /// exactly as `TelemetryEvent` does.
  ///
  /// [latency] is left out on purpose: it is derived from the two timestamps, and
  /// a second copy of it on the wire is one that can disagree with them.
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
