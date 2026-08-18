import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

import '../entities/telemetry_reader.dart';
import '../entities/telemetry_reader_exception.dart';

/// Talks to `GET /events` and `GET /latency` on the local API.
class HttpTelemetryReader implements TelemetryReader {
  HttpTelemetryReader({required this._client, required this._baseUrl});

  final http.Client _client;
  final Uri _baseUrl;

  @override
  Future<List<TelemetryEvent>> recentEvents({int limit = 500}) async => [
    for (final row in await _list(
      () => _client.get(
        _baseUrl.replace(path: '/events', queryParameters: {'limit': '$limit'}),
      ),
    ))
      TelemetryEvent.fromJson(_asObject(row)),
  ];

  @override
  Future<List<LatencyRow>> latencies() async => [
    for (final row in await _list(
      () => _client.get(_baseUrl.replace(path: '/latency')),
    ))
      LatencyRow.fromJson(_asObject(row)),
  ];

  Future<List<Object?>> _list(Future<http.Response> Function() send) async {
    final decoded = jsonDecode(await _body(send));
    if (decoded is! List) {
      throw TelemetryReaderException(
        'The API answered 200 with ${decoded.runtimeType} where a list was '
        'expected.',
      );
    }

    return decoded;
  }

  /// The usual cause of a failure here is a forgotten port forward, so the remedy goes
  /// in the message rather than in the exception type — as `HttpRunScheduler` does.
  Future<String> _body(Future<http.Response> Function() send) async {
    final http.Response response;
    try {
      response = await send();
    } catch (error) {
      throw TelemetryReaderException(
        'Could not reach $_baseUrl — is the API running?\n'
        'On a physical device, run: adb reverse tcp:8080 tcp:8080\n'
        '($error)',
      );
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw TelemetryReaderException.fromApiError(_errorFrom(response));
    }

    return response.body;
  }
}

/// Reads the server's `ApiError`, falling back to the status code where the body is not
/// one — a proxy or a crash can answer with anything.
ApiError _errorFrom(http.Response response) {
  try {
    return ApiError.fromJson(_asObject(jsonDecode(response.body)));
  } on Object {
    return ApiError(
      'The API answered ${response.statusCode}: ${response.body}',
    );
  }
}

Map<String, dynamic> _asObject(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    throw TelemetryReaderException(
      'Expected a JSON object, got ${decoded.runtimeType}.',
    );
  }

  return decoded;
}
