import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'entities/push_telemetry.dart';

/// The key the send API injects the trace id into.
///
/// A literal here and in `PushMessageParser.reservedKeys`, which is what keeps it
/// out of the inbox's data rows. The parser strips it, so these functions take a
/// payload map rather than a `PushMessage`.
const _traceIdKey = 'trace_id';

const _scenarioIdKey = 'scenario_id';

/// Records [type] against the trace id in [payload], then sends it — for the
/// hooks that know they are in the foreground, where the app is reachable.
Future<void> reportAndFlush(
  PushTelemetry telemetry,
  TelemetryEventType type,
  Map<String, Object?> payload,
) async {
  try {
    if (await _record(telemetry, type, payload)) {
      await telemetry.flush();
    }
  } on Object catch (error) {
    _swallow(type, error);
  }
}

/// Records [type] against the trace id in [payload] and deliberately stops there.
///
/// For the background handler: its isolate can be killed at any moment, and a
/// request in flight when that happens loses the event it was carrying, whereas a
/// buffered row is picked up by the next foreground flush.
Future<void> reportWithoutFlushing(
  PushTelemetry telemetry,
  TelemetryEventType type,
  Map<String, Object?> payload,
) async {
  try {
    await _record(telemetry, type, payload);
  } on Object catch (error) {
    _swallow(type, error);
  }
}

/// Both hooks are called fire-and-forget from a push handler, so an escaping error
/// would arrive as an unhandled async error on the delivery path: telemetry
/// breaking the thing it exists to observe.
void _swallow(TelemetryEventType type, Object error) =>
    debugPrint('telemetry: ${type.wireName} was not reported: $error');

/// Records the event if [payload] carries a trace id, answering whether it did.
///
/// A payload with no trace id records nothing at all — not a fabricated id. A push
/// sent by hand with `curl` has none, and a made-up trace would appear in the
/// matrix as a message nobody sent, which is worse than a gap.
Future<bool> _record(
  PushTelemetry telemetry,
  TelemetryEventType type,
  Map<String, Object?> payload,
) async {
  final traceId = _textIn(payload, _traceIdKey);
  if (traceId == null) {
    return false;
  }

  await telemetry.record(
    type,
    traceId: traceId,
    scenarioId: _textIn(payload, _scenarioIdKey),
  );

  return true;
}

/// FCM data values are strings on the wire, but the plugin surfaces them as
/// `Object?`, and a blank id correlates to as much as an absent one.
String? _textIn(Map<String, Object?> payload, String key) {
  final value = payload[key];

  return value is String && value.trim().isNotEmpty ? value : null;
}
