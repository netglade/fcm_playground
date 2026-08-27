import 'dart:io';

import 'package:fcm_api/src/fcm_send_exception.dart';
import 'package:fcm_api/src/fcm_sender.dart';
import 'package:fcm_api/src/send_outcome.dart';
import 'package:fcm_api/src/telemetry_store.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Injects the target and a trace id into the message and forwards it to FCM,
/// recording `queued` before FCM is asked and the result after.
///
/// The payload is otherwise the caller's. The clock, id generator and
/// [TelemetryStore] are parameters, so tests assert exact values and this needs
/// no `Request`, credential or socket.
///
/// Five parameters is the limit — `number-of-parameters: 5` is fatal — so a
/// sixth means gathering them into an object.
Future<SendOutcome> sendMessage(
  SendMessageRequest request, {
  required FcmSender sender,
  required DateTime Function() now,
  required String Function() newTraceId,
  required TelemetryStore telemetry,
}) async {
  if (request.target case AllDevicesTarget()) {
    // Nothing recorded: a lone `queued` row would read as a message lost in
    // flight rather than one never accepted.
    return allDevicesUnsupported;
  }

  // Minted once, so the id on the wire and the id returned are the same one.
  final traceId = newTraceId();
  // One reading stamps every event of this send; two would separate `queued`
  // from `sent` by however long FCM took. Hence `TelemetryStore.all` being
  // specified in recorded order.
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
    // The code, not the prose: codes group a hundred failures into three
    // causes.
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

/// Stores one event, swallowing any failure: losing a row is a nuisance, but
/// failing a push because the event store was down is a bug in a tool whose only
/// job is sending pushes.
Future<void> _record(TelemetryStore telemetry, TelemetryEvent event) async {
  try {
    await telemetry.record([event]);
  } on Object catch (error) {
    stderr.writeln(
      'telemetry: dropped ${event.type.wireName} for ${event.traceId}: $error',
    );
  }
}

/// One of the three send-side events. `deviceId` is empty because these happen
/// on the server, and `scenarioId` comes off the request — the payload a scenario
/// produces does not identify it.
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
/// Builds a new map: `FcmMessage.toJson` passes `data` by reference, so writing
/// in place would rewrite the caller's own — and throw for a `const` template.
Map<String, Object?> _bodyFor(SendMessageRequest request, String traceId) {
  final message = request.message.toJson();

  return {
    'validate_only': request.validateOnly,
    'message': {
      ...message,
      'data': {
        ...?message['data'] as Map<String, String>?,
        'trace_id': traceId,
        // Injected as well as recorded, or the device's arrival events carry
        // no scenario.
        'scenario_id': ?request.scenarioId,
      },
      ...request.target.toJson(),
    },
  };
}

/// AllDevices is the one target FCM cannot express — honouring it would need a
/// token registry this app does not keep, and sending to one device while calling
/// it a broadcast is worse than refusing.
///
/// Public because `POST /runs` refuses it at scheduling time in the same words: a
/// run must never hold an item that cannot send.
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

/// A stale token is the common failure and gets its own wording —
/// `UNREGISTERED` tells the person holding the phone nothing.
String _messageFor(FcmSendException error) => switch (error.status) {
  'UNREGISTERED' =>
    'The registration token is no longer valid — the app was reinstalled or '
        'the token rotated. Restart the app to get a fresh one.',
  'INVALID_ARGUMENT' => 'FCM rejected the message: ${error.message}',
  _ => 'FCM failed (${error.status}): ${error.message}',
};
