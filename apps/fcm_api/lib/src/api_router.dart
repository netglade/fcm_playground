import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'events_handler.dart';
import 'fcm_sender.dart';
import 'send_message.dart';
import 'send_outcome.dart';
import 'telemetry_store.dart';

/// The HTTP surface: four routes, JSON in and JSON out.
///
/// It decides nothing about a send — [sendMessage] returns the status and
/// the body, and this class only translates between that and `shelf`.
class ApiRouter {
  /// [now] and [newTraceId] are injected rather than read from the environment, so
  /// a test asserts exact values instead of matching patterns. One [telemetry] store
  /// serves all three routes, since a latency pairs a device's row with a send's.
  ApiRouter({
    required this._sender,
    required this._now,
    required this._newTraceId,
    required this._telemetry,
  });

  final FcmSender _sender;
  final DateTime Function() _now;
  final String Function() _newTraceId;
  final TelemetryStore _telemetry;

  Handler get handler {
    final router = Router(notFoundHandler: _notFound)
      ..get('/health', _health)
      ..post('/send', _send)
      ..post('/events', _events)
      ..get('/latency', _latency);

    return router.call;
  }

  Response _health(Request request) => _json(200, const {'status': 'ok'});

  Future<Response> _send(Request request) =>
      _parsedBody(request, SendMessageRequest.fromJson, _sent);

  Future<Response> _sent(SendMessageRequest parsed) async {
    final outcome = await sendMessage(
      parsed,
      sender: _sender,
      now: _now,
      newTraceId: _newTraceId,
      telemetry: _telemetry,
    );

    return switch (outcome) {
      SendSucceeded(:final response) => _json(200, response.toJson()),
      SendRejected(:final statusCode, :final error) => _json(
        statusCode,
        error.toJson(),
      ),
    };
  }

  /// The count comes from the store rather than from the request: a replay answers
  /// 200 with zero, and a 4xx there would make a client that already succeeded retry
  /// forever.
  Future<Response> _events(Request request) => _parsedBody(
    request,
    readEventBatch,
    (events) async => _json(200, {'recorded': await _telemetry.record(events)}),
  );

  Future<Response> _latency(Request request) async =>
      _json(200, latencyBody(await _telemetry.latencies()));

  /// Reads the body with [parse] and hands the result to [respond], answering 400
  /// with the message of any [FormatException] the parse throws.
  ///
  /// [respond] runs outside the `catch` on purpose: a [FormatException] from deeper
  /// in a send is a server-side surprise, and reporting it as a bad request would
  /// blame the caller for it.
  Future<Response> _parsedBody<T>(
    Request request,
    T Function(Map<String, Object?> body) parse,
    Future<Response> Function(T parsed) respond,
  ) async {
    final T parsed;
    try {
      parsed = parse(_decodeObject(await request.readAsString()));
    } on FormatException catch (error) {
      return _json(400, ApiError(error.message).toJson());
    }

    return respond(parsed);
  }

  Response _notFound(Request request) => _json(
    404,
    const ApiError(
      'No such route. The API has POST /send, POST /events, GET /latency and '
      'GET /health.',
    ).toJson(),
  );
}

/// A JSON array or a bare value is as malformed as broken JSON, and both must reach
/// the caller as a 400 rather than as a cast failure.
Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(
      'The body must be a JSON object, got ${decoded.runtimeType}',
    );
  }

  return decoded;
}

/// Writes a JSON body, which is an object for every route but `GET /latency` —
/// hence [Object?] rather than a map: a list of rows is the honest shape for a
/// collection, and wrapping it in a one-key object would be a shape the app then
/// has to unwrap.
Response _json(int statusCode, Object? body) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: const {'content-type': 'application/json'},
);
