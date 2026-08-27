import 'package:fcm_gallery_shared/src/json_field.dart';
import 'package:fcm_gallery_shared/src/telemetry/telemetry_event_type.dart';

/// One recorded moment in a message's life, on the API or on a device.
///
/// Events are correlated by [traceId], which the API mints per send, and grouped
/// by [deviceId], because two handsets receiving one broadcast are two
/// measurements rather than a duplicate.
class TelemetryEvent {
  /// Normalises [at] to UTC, which is why this is not `const`: a latency computed
  /// between a device on local time and a server on UTC is out by hours, and reads
  /// as a delivery fault rather than as the bug it is.
  TelemetryEvent({
    required this.traceId,
    required this.type,
    required DateTime at,
    required this.deviceId,
    this.scenarioId,
    this.detail,
  }) : at = at.toUtc();

  factory TelemetryEvent.fromJson(Map<String, Object?> json) => TelemetryEvent(
    traceId: requireText(json['trace_id'], 'trace_id'),
    type: _typeFrom(requireText(json['type'], 'type')),
    at: requireTimestamp(json['at'], 'at'),
    deviceId: requireText(json['device_id'], 'device_id'),
    scenarioId: _nullableText(json['scenario_id'], 'scenario_id'),
    detail: _nullableText(json['detail'], 'detail'),
  );

  /// Minted by the API and carried in the message's `data`.
  final String traceId;

  final TelemetryEventType type;

  /// Always in UTC.
  final DateTime at;

  /// `''` for the events the API itself records — a server-side event has no device.
  final String deviceId;

  /// Absent for a send made by hand, which is why it is nullable rather than
  /// defaulted: the difference matters when reading the matrix.
  final String? scenarioId;

  /// Whatever this event type says it carries — FCM's message id, an error code, the
  /// app state on a tap.
  final String? detail;

  /// Omits the optional fields rather than writing them as null: a
  /// `scenario_id: null` on the wire is noise the other side then has to handle.
  Map<String, Object?> toJson() => {
    'trace_id': traceId,
    'type': type.wireName,
    'at': at.toIso8601String(),
    'device_id': deviceId,
    'scenario_id': ?scenarioId,
    'detail': ?detail,
  };

  @override
  bool operator ==(Object other) =>
      other is TelemetryEvent &&
      traceId == other.traceId &&
      type == other.type &&
      at == other.at &&
      deviceId == other.deviceId &&
      scenarioId == other.scenarioId &&
      detail == other.detail;

  @override
  int get hashCode =>
      Object.hash(traceId, type, at, deviceId, scenarioId, detail);

  @override
  String toString() =>
      'TelemetryEvent(${type.wireName} $traceId $deviceId at $at)';
}

/// Refuses to guess at an unknown wire name: it is indistinguishable from a typo,
/// and a default would put an event of the wrong kind into the matrix.
TelemetryEventType _typeFrom(String wireName) {
  for (final type in TelemetryEventType.values) {
    if (type.wireName == wireName) {
      return type;
    }
  }

  throw FormatException('"type" has unknown value "$wireName"');
}

/// The shared [readOptionalText] treats absence as `''`, which is right for a field
/// a validator later reports on but wrong here: `''` and "not set" are different
/// answers to "which scenario sent this?".
String? _nullableText(Object? value, String field) {
  if (value == null) {
    return null;
  }

  return readOptionalText(value, field);
}
