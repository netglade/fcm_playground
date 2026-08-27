import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

import '../../i18n/translations.g.dart';
import 'telemetry_reader.dart';
import 'telemetry_reader_exception.dart';

/// Talks to `GET /events` and `GET /latency` on the local API.
class HttpTelemetryReader implements TelemetryReader {
  HttpTelemetryReader({required this._client, required this._baseUrl});

  final http.Client _client;
  final Uri _baseUrl;

  @override
  Future<List<TelemetryEvent>> recentEvents({int limit = 500}) async => _rows(
    await _list(
      () => _client.get(
        _baseUrl.replace(path: '/events', queryParameters: {'limit': '$limit'}),
      ),
    ),
    TelemetryEvent.fromJson,
    t.api.item.event,
  );

  @override
  Future<List<LatencyRow>> latencies() async => _rows(
    await _list(() => _client.get(_baseUrl.replace(path: '/latency'))),
    LatencyRow.fromJson,
    t.api.item.latency_row,
  );

  Future<List<Object?>> _list(Future<http.Response> Function() send) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await _body(send));
    } on FormatException catch (error) {
      throw TelemetryReaderException(
        t.api.answered_not_json(error: error.message),
      );
    }
    if (decoded is! List) {
      throw TelemetryReaderException(
        t.api.answered_wrong_shape(type: decoded.runtimeType),
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
        t.api.unreachable(baseUrl: _baseUrl, error: error),
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
      t.api.answered_status(status: response.statusCode, body: response.body),
    );
  }
}

Map<String, dynamic> _asObject(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    throw TelemetryReaderException(
      t.api.expected_object(type: decoded.runtimeType),
    );
  }

  return decoded;
}

/// Parses each row of [decoded] with [parse], turning a body this build cannot read
/// into a message rather than a raw [FormatException].
///
/// A 200 the app cannot parse is still a failure the page has to show: the cubit that
/// reads this catches [TelemetryReaderException] and nothing else, so anything raw
/// escaping here would become an unhandled error instead of a line on the screen.
List<T> _rows<T>(
  List<Object?> decoded,
  T Function(Map<String, Object?> json) parse,
  String what,
) {
  try {
    return [for (final row in decoded) parse(_asObject(row))];
  } on FormatException catch (error) {
    throw TelemetryReaderException(
      t.api.answered_unreadable_item(what: what, error: error.message),
    );
  }
}
