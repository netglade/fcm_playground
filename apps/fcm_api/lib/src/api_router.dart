import 'dart:convert';

import 'package:fcm_api/src/events_handler.dart';
import 'package:fcm_api/src/fcm_sender.dart';
import 'package:fcm_api/src/send_message.dart';
import 'package:fcm_api/src/send_outcome.dart';
import 'package:fcm_api/src/send_scheduler.dart';
import 'package:fcm_api/src/telemetry_store.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// The HTTP surface: nine routes, JSON in and JSON out.
///
/// Decides nothing about a send — [sendMessage] returns the status and body,
/// this only translates between that and `shelf`.
class ApiRouter {
  /// [now] and [newTraceId] are injected so tests assert exact values rather
  /// than match patterns. One [telemetry] store serves every route, since a
  /// latency pairs a device's row with a send's.
  ApiRouter({
    required this._sender,
    required this._now,
    required this._newTraceId,
    required this._telemetry,
    required this._scheduler,
  });

  final FcmSender _sender;
  final DateTime Function() _now;
  final String Function() _newTraceId;
  final TelemetryStore _telemetry;
  final SendScheduler _scheduler;

  Handler get handler {
    final router = Router(notFoundHandler: _notFound)
      ..get('/health', _health)
      ..post('/send', _send)
      ..post('/runs', _createRun)
      ..get('/runs', _runs)
      ..get('/runs/<id>', _run)
      ..delete('/runs/<id>', _cancelRun)
      ..post('/events', _events)
      ..get('/events', _recentEvents)
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

  Future<Response> _createRun(Request request) =>
      _parsedBody(request, ScheduleRunRequest.fromJson, _scheduled);

  /// The "every device" check runs before anything is stored, so a run never
  /// holds an unsendable item. The wording is `sendMessage`'s own, not a copy
  /// that could drift.
  Future<Response> _scheduled(ScheduleRunRequest request) async {
    if (request.items.any((item) => item.target is AllDevicesTarget)) {
      return _json(
        allDevicesUnsupported.statusCode,
        allDevicesUnsupported.error.toJson(),
      );
    }

    final run = await _scheduler.schedule(request, _now());

    return _json(201, run.toJson());
  }

  /// Summaries only — a list does not need sixty-six payloads per row, and the
  /// detail route is one tap away.
  Future<Response> _runs(Request request) async => _json(200, [
    for (final summary in await _scheduler.recent()) summary.toJson(),
  ]);

  Future<Response> _run(Request request, String id) async {
    final run = await _scheduler.find(id);
    if (run == null) {
      return _json(404, ApiError('There is no run "$id".').toJson());
    }

    return _json(200, (await _withEvents(run)).toJson());
  }

  /// 404 means "no such run"; "nothing left to cancel" answers 200 with zero —
  /// pressing Cancel a moment too late is not an error.
  Future<Response> _cancelRun(Request request, String id) async {
    final cancelled = await _scheduler.cancel(id);
    if (cancelled == null) {
      return _json(404, ApiError('There is no run "$id".').toJson());
    }

    return _json(200, {'cancelled': cancelled});
  }

  /// Attaches each item's telemetry, in one query for the whole run.
  ///
  /// The only place the two are joined — a copy in the run store could
  /// disagree.
  Future<ScheduledRun> _withEvents(ScheduledRun run) async {
    final traceIds = [for (final item in run.items) ?item.traceId];
    if (traceIds.isEmpty) {
      return run;
    }

    final byTrace = <String, List<TelemetryEvent>>{};
    for (final event in await _telemetry.eventsForTraces(traceIds)) {
      (byTrace[event.traceId] ??= []).add(event);
    }

    return ScheduledRun(
      id: run.id,
      createdAt: run.createdAt,
      items: [
        for (final item in run.items)
          item.copyWith(events: byTrace[item.traceId] ?? const []),
      ],
    );
  }

  /// The count comes from the store, not the request: a replay answers 200 with
  /// zero, and a 4xx would make an already-successful client retry forever.
  Future<Response> _events(Request request) => _parsedBody(
    request,
    readEventBatch,
    (events) async => _json(200, {'recorded': await _telemetry.record(events)}),
  );

  /// The recent events, newest first, for the app's telemetry page. Bounded — a
  /// page wants the last screenful, not the whole table.
  Future<Response> _recentEvents(Request request) async {
    final int limit;
    try {
      limit = readEventLimit(request.url.queryParameters['limit']);
    } on FormatException catch (error) {
      return _json(400, ApiError(error.message, field: 'limit').toJson());
    }

    return _json(200, eventsBody(await _telemetry.recent(limit: limit)));
  }

  Future<Response> _latency(Request request) async =>
      _json(200, latencyBody(await _telemetry.latencies()));

  /// Reads the body with [parse] and hands the result to [respond], answering
  /// 400 with any [FormatException] the parse throws.
  ///
  /// [respond] runs outside the `catch` deliberately: a [FormatException] from
  /// deeper in a send is a server-side surprise, and a 400 would blame the
  /// caller.
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
      'No such route. The API has POST /send, POST /runs, GET /runs, '
      'GET /runs/<id>, DELETE /runs/<id>, POST /events, GET /events, '
      'GET /latency and GET /health.',
    ).toJson(),
  );
}

/// A JSON array or bare value is as malformed as broken JSON here, and must
/// reach the caller as a 400 rather than a cast failure.
Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(
      'The body must be a JSON object, got ${decoded.runtimeType}',
    );
  }

  return decoded;
}

/// Writes a JSON body — an object for every route but `GET /latency`, hence
/// [Object?]: a list is the honest shape for a collection, and a one-key wrapper
/// would only need unwrapping.
Response _json(int statusCode, Object? body) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: const {'content-type': 'application/json'},
);
