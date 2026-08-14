import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'push_telemetry.dart';

/// The key the send API injects the trace id into.
///
/// A literal here and in `PushMessageParser.reservedKeys`, which is what keeps it
/// out of the inbox's data rows. The parser strips it, so a hook cannot read the
/// trace id off a `PushMessage` — it has to read the payload the parser was
/// given, which is why these functions take a map rather than a message.
const _traceIdKey = 'trace_id';

/// The key the send API injects the scenario id into, when the send came from
/// the catalogue rather than from a hand-composed payload.
const _scenarioIdKey = 'scenario_id';

/// Records [type] against the trace id in [payload], then sends it.
///
/// For the hooks that know they are in the foreground — an arrival on the live
/// stream, a banner drawn, a tap handled. The app is running and reachable, so
/// there is no reason to leave the event sitting in the buffer.
///
/// Nothing is sent when nothing was recorded: a flush of an empty buffer is a
/// request that can only fail.
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

/// Records [type] against the trace id in [payload] and deliberately stops
/// there.
///
/// For the background handler. Its isolate can be killed at any moment, and a
/// request that was in flight when that happens loses the event it was carrying
/// — whereas a buffered row is picked up by the next foreground flush. The
/// reporter cannot make this decision itself, because it cannot see which
/// isolate called it, so it belongs here at the call site.
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

/// Reports a hook's own failure to the console and nowhere else.
///
/// Both hooks are called fire-and-forget from a push handler, so an escaping
/// error would arrive as an unhandled asynchronous error on the delivery path:
/// telemetry breaking the thing it exists to observe. The reporter already
/// promises this for `record`; a `flush` that cannot read its own database is the
/// half left over, and it is these call sites that introduced it.
void _swallow(TelemetryEventType type, Object error) =>
    debugPrint('telemetry: ${type.wireName} was not reported: $error');

/// Records the event if [payload] carries a trace id, answering whether it did.
///
/// **A payload with no trace id records nothing at all.** Not a fabricated id: a
/// push sent by hand with `curl` has none, and a made-up trace would appear in
/// the matrix as a message nobody sent, which is a worse answer than a gap.
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

/// The usable text at [key], or null when there is none.
///
/// FCM data values are strings on the wire, but the plugin surfaces them as
/// `Object?`, and a blank id correlates to exactly as much as an absent one — so
/// both answer null rather than reaching the database.
String? _textIn(Map<String, Object?> payload, String key) {
  final value = payload[key];

  return value is String && value.trim().isNotEmpty ? value : null;
}
