import 'dart:io';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';
import 'send_outcome.dart';
import 'telemetry_store.dart';

/// Injects the delivery target and a trace id into the message and forwards it
/// to FCM.
///
/// The payload is otherwise the caller's: nothing here invents a notification
/// block or a data key of its own — [request.message] is forwarded untouched
/// apart from the [request.target] injected as the delivery target and the
/// trace id injected into `data`. Takes its clock, its id generator and its
/// [TelemetryStore] as parameters rather than reading any of them from the
/// environment, so its tests assert exact values instead of matching patterns —
/// and it depends on no `Request`, no credential and no socket.
///
/// It records the send side of the pipeline as it goes: `queued` before FCM is
/// asked, then `sent` or `send_failed`. **These five parameters are the limit**
/// — `number-of-parameters: 5` is fatal here — so a sixth needs the arguments
/// gathered into an object rather than appended.
Future<SendOutcome> sendMessage(
  SendMessageRequest request, {
  required FcmSender sender,
  required DateTime Function() now,
  required String Function() newTraceId,
  required TelemetryStore telemetry,
}) async {
  if (request.target case AllDevicesTarget()) {
    // Nothing is recorded, deliberately: the refusal happens before anything is
    // queued, and a `queued` row with no `sent` or `send_failed` beside it would
    // read as a message lost in flight rather than one never accepted.
    return _allDevicesUnsupported;
  }

  // Minted once, so the id on the wire and the id returned are the same one.
  final traceId = newTraceId();
  // One clock reading stamps every event of this send, which is why
  // `TelemetryStore.all` is specified in recorded order: two readings would
  // separate `queued` from `sent` by however long FCM took, and nothing here
  // wants to measure that — the figure this pipeline exists for is
  // `sent → received`.
  final at = now();
  final scenarioId = request.scenarioId;
  await _record(
    telemetry,
    _event(traceId, TelemetryEventType.queued, at, scenarioId: scenarioId),
  );

  try {
    final messageId = await sender.send(_bodyFor(request, traceId));
    // FCM's own name for the message, which is what ties this trace to Google's
    // record of the same send.
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

/// Stores one event, swallowing whatever the store does about it.
///
/// Telemetry observes something more important than itself. Losing a row is a
/// nuisance; failing a push because the event store was unavailable would be a
/// bug in a tool whose only purpose is sending pushes. The reason goes to
/// `stderr` rather than nowhere, so a store that is quietly failing is still
/// visible to whoever is watching the server.
Future<void> _record(TelemetryStore telemetry, TelemetryEvent event) async {
  try {
    await telemetry.record([event]);
  } on Object catch (error) {
    stderr.writeln(
      'telemetry: dropped ${event.type.wireName} for ${event.traceId}: $error',
    );
  }
}

/// One of the three send-side events.
///
/// `deviceId` is empty because these happen on the server, with no device
/// involved yet. `scenarioId` comes off the request, which is the only way it can
/// be known here: the payload a scenario produces does not identify the scenario,
/// so without the sender naming it the `scenario × device` matrix would have no
/// scenario axis on either side.
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
/// The merge builds a **new** map. `FcmMessage.toJson` returns a fresh outer map
/// but passes `data` through by reference, so writing into that map in place
/// would rewrite the caller's own — and for the `const` scenario templates, or
/// the unmodifiable map `FcmMessage.fromJson` produces, it would throw instead.
/// Neither is a way to send a push.
Map<String, Object?> _bodyFor(SendMessageRequest request, String traceId) {
  final message = request.message.toJson();

  return {
    'validate_only': request.validateOnly,
    'message': {
      ...message,
      'data': {
        ...?message['data'] as Map<String, String>?,
        'trace_id': traceId,
        // Injected as well as recorded, so the DEVICE knows which scenario it is
        // holding. Its arrival events carry no scenario otherwise, and a matrix
        // whose rows come only from the send side could not tell which handset
        // received which scenario.
        'scenario_id': ?request.scenarioId,
      },
      ...request.target.toJson(),
    },
  };
}

/// AllDevices is the one target FCM cannot express: it has no such audience, so
/// honouring it needs a registry of tokens this app does not keep. Refusing with
/// a reason beats sending to one device and calling it a broadcast.
const _allDevicesUnsupported = SendRejected(
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
