import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'fcm_sender.dart';
import 'send_message.dart';
import 'send_outcome.dart';

/// The HTTP surface: two routes, JSON in and JSON out.
///
/// It decides nothing about a send — [sendMessage] returns the status and
/// the body, and this class only translates between that and `shelf`.
class ApiRouter {
  /// Creates the router. [sender] delivers through FCM; [now] supplies the
  /// clock used to stamp a successful send, and [newTraceId] the id each send is
  /// traced by — both injected rather than read from the environment, so a test
  /// asserts exact values instead of matching patterns.
  ApiRouter({
    required this._sender,
    required this._now,
    required this._newTraceId,
  });

  final FcmSender _sender;
  final DateTime Function() _now;
  final String Function() _newTraceId;

  /// The handler to serve.
  Handler get handler {
    final router = Router(notFoundHandler: _notFound)
      ..get('/health', _health)
      ..post('/send', _send);

    return router.call;
  }

  Response _health(Request request) => _json(200, const {'status': 'ok'});

  Future<Response> _send(Request request) async {
    final SendMessageRequest parsed;
    try {
      parsed = SendMessageRequest.fromJson(
        _decodeObject(await request.readAsString()),
      );
    } on FormatException catch (error) {
      return _json(400, ApiError(error.message).toJson());
    }

    final outcome = await sendMessage(
      parsed,
      sender: _sender,
      now: _now,
      newTraceId: _newTraceId,
    );

    return switch (outcome) {
      SendSucceeded(:final response) => _json(200, response.toJson()),
      SendRejected(:final statusCode, :final error) => _json(
        statusCode,
        error.toJson(),
      ),
    };
  }

  Response _notFound(Request request) => _json(
    404,
    const ApiError(
      'No such route. The API has POST /send and GET /health.',
    ).toJson(),
  );
}

/// Decodes a request body that must be a JSON object.
///
/// A JSON array or a bare value is as malformed as broken JSON, and both must
/// reach the caller as a 400 rather than as a cast failure.
Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(
      'The body must be a JSON object, got ${decoded.runtimeType}',
    );
  }

  return decoded;
}

Response _json(int statusCode, Map<String, dynamic> body) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: const {'content-type': 'application/json'},
);
