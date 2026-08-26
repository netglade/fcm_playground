import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

import '../../../i18n/translations.g.dart';
import '../entities/run_scheduler.dart';
import '../entities/run_scheduler_exception.dart';

/// Talks to `/runs` on the local API.
class HttpRunScheduler implements RunScheduler {
  HttpRunScheduler({required this._client, required this._baseUrl});

  final http.Client _client;
  final Uri _baseUrl;

  @override
  Future<ScheduledRun> schedule(ScheduleRunRequest request) async =>
      ScheduledRun.fromJson(
        await _object(
          () => _client.post(
            _baseUrl.replace(path: '/runs'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(request.toJson()),
          ),
        ),
      );

  @override
  Future<List<RunSummary>> list() async => [
    for (final row in await _list(
      () => _client.get(_baseUrl.replace(path: '/runs')),
    ))
      RunSummary.fromJson(_asObject(row)),
  ];

  @override
  Future<ScheduledRun> fetch(String runId) async => ScheduledRun.fromJson(
    await _object(() => _client.get(_baseUrl.replace(path: '/runs/$runId'))),
  );

  @override
  Future<int> cancel(String runId) async {
    final body = await _object(
      () => _client.delete(_baseUrl.replace(path: '/runs/$runId')),
    );

    // `requireInt` rather than a blind `as int? ?? 0`: the same pattern was
    // removed from `RunSummary.fromJson` for the same reason — a wrongly-typed
    // value (`{"cancelled": "3"}`) must fail loudly, not silently become 0.
    return requireInt(body['cancelled'], 'cancelled');
  }

  Future<Map<String, dynamic>> _object(
    Future<http.Response> Function() send,
  ) async => _asObject(jsonDecode(await _body(send)));

  Future<List<Object?>> _list(Future<http.Response> Function() send) async {
    final decoded = jsonDecode(await _body(send));
    if (decoded is! List) {
      throw RunSchedulerException(
        t.api.answered_wrong_shape_runs(type: decoded.runtimeType),
      );
    }

    return decoded;
  }

  /// The usual cause of a failure here is a forgotten port forward, so the remedy
  /// goes in the message rather than in the exception type — as
  /// `HttpNotificationSender` already does.
  Future<String> _body(Future<http.Response> Function() send) async {
    final http.Response response;
    try {
      response = await send();
    } catch (error) {
      throw RunSchedulerException(
        t.api.unreachable(baseUrl: _baseUrl, error: error),
      );
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw RunSchedulerException.fromApiError(_errorFrom(response));
    }

    return response.body;
  }
}

/// Reads the server's `ApiError`, falling back to the status code where the body is
/// not one — a proxy or a crash can answer with anything.
ApiError _errorFrom(http.Response response) {
  try {
    return ApiError.fromJson(_asObject(jsonDecode(response.body)));
  } on Object {
    return ApiError(
      t.api.answered_status(status: response.statusCode, body: response.body),
    );
  }
}

Map<String, dynamic> _asObject(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    throw RunSchedulerException(
      t.api.expected_object(type: decoded.runtimeType),
    );
  }

  return decoded;
}
