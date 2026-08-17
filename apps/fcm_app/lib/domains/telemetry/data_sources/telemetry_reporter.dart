import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'device_identity.dart';
import 'push_telemetry.dart';
import 'telemetry_buffer.dart';

/// Records what happens to a push on this device, and sends it to the API.
///
/// The two halves are deliberately separate calls. [record] stores and returns;
/// [flush] is what talks to the network. Recording happens inside push
/// handlers — including the background isolate, which can be killed at any
/// moment — and a handler is not in a position to know whether a request is safe
/// to start, so that decision belongs to whoever wires the hook up rather than
/// to a reporter that cannot see it.
class TelemetryReporter implements PushTelemetry {
  /// Reports for the install [_identity] names, buffering in [_buffer] and
  /// sending to [_baseUrl].
  ///
  /// [client] is injected only so tests can answer without a server; a real app
  /// gets its own.
  TelemetryReporter({
    required this._buffer,
    required this._identity,
    required this._baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final TelemetryBuffer _buffer;
  final DeviceIdentity _identity;
  final Uri _baseUrl;
  final http.Client _client;

  /// Buffers one event of [type] against [traceId], stamping the rest.
  ///
  /// The time and the device id are filled in here so no caller has to remember
  /// either: a hook that stamped its own time could stamp a local one, and a
  /// latency computed against a UTC server would then be out by hours and read
  /// as a delivery fault.
  ///
  /// **This never throws.** It is called from inside push handlers, where an
  /// exception would take down the delivery it is only supposed to observe —
  /// which is strictly worse than a missing row. A failure is reported to the
  /// debug console rather than nowhere, so a device that is quietly recording
  /// nothing is still visible to whoever is looking.
  @override
  Future<void> record(
    TelemetryEventType type, {
    required String traceId,
    String? scenarioId,
    String? detail,
  }) async {
    try {
      await _buffer.add(
        TelemetryEvent(
          traceId: traceId,
          type: type,
          at: DateTime.now().toUtc(),
          deviceId: await _identity.id(),
          scenarioId: scenarioId,
          detail: detail,
        ),
      );
    } on Object catch (error) {
      debugPrint('telemetry: dropped ${type.wireName} for $traceId: $error');
    }
  }

  /// Sends what is buffered, deleting only what the API acknowledges.
  ///
  /// A batch that is not answered with a `200` stays buffered for the next
  /// flush: dropping it would turn a failed request into a gap that looks
  /// exactly like a message that never arrived. Only the rows that were sent are
  /// forgotten, because events arrive *during* a flush and a blanket clear would
  /// delete observations that were never sent.
  @override
  Future<void> flush() async {
    final pending = await _buffer.pending();
    if (pending.isEmpty) {
      // A flush of nothing is a request that can only fail, and the API would
      // answer `{"recorded": 0}` to it.
      return;
    }

    if (await _post(pending)) {
      await _buffer.forget(pending);
    }
  }

  /// Posts [pending] as one batch, answering whether the API stored all of it.
  ///
  /// `POST /events` is all-or-nothing, so one boolean is the whole answer:
  /// either every row is on the server or none is, and there is no half of the
  /// batch to forget. A transport failure is the same answer as a rejection —
  /// nothing was stored — and is expected often enough (a handset on a train,
  /// a forgotten `adb reverse`) that it is a normal outcome here rather than an
  /// error to raise.
  Future<bool> _post(List<PendingEvent> pending) async {
    try {
      final response = await _client.post(
        _baseUrl.replace(path: '/events'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'events': [for (final entry in pending) entry.event.toJson()],
        }),
      );
      if (response.statusCode != 200) {
        debugPrint(
          'telemetry: $_baseUrl answered ${response.statusCode}, '
          'keeping ${pending.length} event(s)',
        );

        return false;
      }

      return true;
    } on Object catch (error) {
      debugPrint(
        'telemetry: could not reach $_baseUrl, '
        'keeping ${pending.length} event(s): $error',
      );

      return false;
    }
  }
}
