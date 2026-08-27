import 'dart:io';

import 'package:fcm_api/src/fcm_send_exception.dart';
import 'package:fcm_api/src/fcm_sender.dart';
import 'package:fcm_api/src/send_outcome.dart';
import 'package:fcm_api/src/telemetry_store.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Injects the delivery target and a trace id into the message and forwards it to
/// FCM, recording `queued` before FCM is asked and then `sent` or `send_failed`.
///
/// The payload is otherwise the caller's. The clock, the id generator and the
/// [TelemetryStore] are parameters rather than read from the environment, so the
/// tests assert exact values and this depends on no `Request`, credential or socket.
///
/// Five parameters is the limit here — `number-of-parameters: 5` is fatal — so a
/// sixth needs them gathered into an object.
Future<SendOutcome> sendMessage(
  SendMessageRequest request, {
  required FcmSender sender,
  required DateTime Function() now,
  required String Function() newTraceId,
  required TelemetryStore telemetry,
}) async {
  if (request.target case AllDevicesTarget()) {
    // Nothing is recorded: a `queued` row with no `sent` or `send_failed` beside
    // it would read as a message lost in flight rather than one never accepted.
    return allDevicesUnsupported;
  }

  // Minted once, so the id on the wire and the id returned are the same one.
  final traceId = newTraceId();
  // One clock reading stamps every event of this send — two would separate
  // `queued` from `sent` by however long FCM took, which nobody wants to measure.
  // Hence `TelemetryStore.all` being specified in recorded order.
  final at = now();
  final scenarioId = request.scenarioId;
  await _record(
    telemetry,
    _event(traceId, TelemetryEventType.queued, at, scenarioId: scenarioId),
  );

  try {
    final messageId = await sender.send(_bodyFor(request, traceId));
    // FCM's own name for the message, which ties this trace to Google's record.
    await _record(
      telemetry,
      _event(
        traceId,
        TelemetryEventType.sent,
        at,
        scenarioId: scenarioId,
        detail: messageId,
      ),
    );

    return SendSucceeded(
      SendMessageResponse(messageId: messageId, sentAt: at, traceId: traceId),
    );
  } on FcmSendException catch (error) {
    // The code rather than the human message: the code is what groups a hundred
    // failures into three causes, and the prose varies with the request.
    await _record(
      telemetry,
      _event(
        traceId,
        TelemetryEventType.sendFailed,
        at,
        scenarioId: scenarioId,
        detail: error.status,
      ),
    );

    return SendRejected(
      statusCode: _statusFor(error.status),
      error: ApiError(_messageFor(error)),
    );
  }
}

/// Stores one event, swallowing whatever the store does about it: losing a row is a
/// nuisance, failing a push because the event store was unavailable is a bug in a
/// tool whose only purpose is sending pushes.
Future<void> _record(TelemetryStore telemetry, TelemetryEvent event) async {
  try {
    await telemetry.record([event]);
  } on Object catch (error) {
    stderr.writeln(
      'telemetry: dropped ${event.type.wireName} for ${event.traceId}: $error',
    );
  }
}

/// One of the three send-side events. `deviceId` is empty because these happen on
/// the server; `scenarioId` comes off the request, which is the only way it can be
/// known here — the payload a scenario produces does not identify the scenario.
TelemetryEvent _event(
  String traceId,
  TelemetryEventType type,
  DateTime at, {
  String? scenarioId,
  String? detail,
}) => TelemetryEvent(
  traceId: traceId,
  type: type,
  at: at,
  deviceId: '',
  scenarioId: scenarioId,
  detail: detail,
);

/// Builds FCM's request body, merging the trace and scenario ids into `data`.
///
/// The merge builds a new map: `FcmMessage.toJson` passes `data` through by
/// reference, so writing into it in place would rewrite the caller's own — and for
/// a `const` scenario template it would throw.
Map<String, Object?> _bodyFor(SendMessageRequest request, String traceId) {
  final message = request.message.toJson();

  return {
    'validate_only': request.validateOnly,
    'message': {
      ...message,
      'data': {
        ...?message['data'] as Map<String, String>?,
        'trace_id': traceId,
        // Injected as well as recorded, so the device knows which scenario it is
        // holding — its arrival events carry no scenario otherwise.
        'scenario_id': ?request.scenarioId,
      },
      ...request.target.toJson(),
    },
  };
}

/// AllDevices is the one target FCM cannot express: it has no such audience, so
/// honouring it means keeping a registry of tokens this app does not keep. Refusing
/// with a reason beats sending to one device and calling it a broadcast.
///
/// Public because `POST /runs` refuses it at scheduling time with the same wording:
/// a run must never hold an item that cannot possibly send.
const allDevicesUnsupported = SendRejected(
  statusCode: 501,
  error: ApiError(
    'sending to all devices needs a token registry, which this API does not '
    'have yet — pick a token, topic or condition',
    field: 'all_devices',
  ),
);

/// FCM's error codes, mapped onto the status the caller should see.
int _statusFor(String fcmStatus) => switch (fcmStatus) {
  'UNREGISTERED' => 404,
  'INVALID_ARGUMENT' => 400,
  _ => 502,
};

/// A stale token is the common failure and gets wording of its own, because
/// `UNREGISTERED` tells the person holding the phone nothing.
String _messageFor(FcmSendException error) => switch (error.status) {
  'UNREGISTERED' =>
    'The registration token is no longer valid — the app was reinstalled or '
        'the token rotated. Restart the app to get a fresh one.',
  'INVALID_ARGUMENT' => 'FCM rejected the message: ${error.message}',
  _ => 'FCM failed (${error.status}): ${error.message}',
};
