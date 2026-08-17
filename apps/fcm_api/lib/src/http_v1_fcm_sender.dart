import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';

/// The one OAuth2 scope this server needs — FCM's HTTP v1 API requires no more to
/// send.
const fcmMessagingScope = 'https://www.googleapis.com/auth/firebase.messaging';

/// Sends through the FCM HTTP v1 REST API.
///
/// The client is injected because in production it is an `AutoRefreshingAuthClient`
/// that adds and refreshes the bearer token itself, and because that leaves the
/// tests able to drive this with a `MockClient` and no credential.
class HttpV1FcmSender implements FcmSender {
  HttpV1FcmSender({required this._client, required this._projectId});

  final http.Client _client;
  final String _projectId;

  @override
  Future<String> send(Map<String, Object?> message) async {
    final response = await _client.post(
      Uri.https('fcm.googleapis.com', '/v1/projects/$_projectId/messages:send'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode != 200) {
      throw _exceptionFrom(response);
    }

    final name = _decode(response.body)?['name'];
    if (name is! String) {
      throw FcmSendException(
        status: 'UNKNOWN',
        message:
            'FCM accepted the message but returned no name: '
            '${response.body}',
      );
    }

    return name;
  }
}

/// The code worth acting on lives in `error.details[].errorCode` — `UNREGISTERED`
/// for a dead token — while `error.status` only carries the generic gRPC name, so
/// the detail wins when it is present.
FcmSendException _exceptionFrom(http.Response response) {
  final error = _decode(response.body)?['error'];
  if (error is! Map<String, Object?>) {
    return FcmSendException(
      status: 'UNKNOWN',
      message: 'FCM answered ${response.statusCode}: ${response.body}',
    );
  }

  final message = error['message'];

  return FcmSendException(
    status:
        _errorCodeIn(error['details']) ?? _textOr(error['status'], 'UNKNOWN'),
    message: _textOr(message, 'FCM answered ${response.statusCode}.'),
  );
}

/// The `errorCode` of the first detail that carries one, or null.
String? _errorCodeIn(Object? details) {
  if (details is! List<Object?>) {
    return null;
  }

  for (final detail in details) {
    if (detail is Map<String, Object?> && detail['errorCode'] is String) {
      return detail['errorCode']! as String;
    }
  }

  return null;
}

Map<String, Object?>? _decode(String body) {
  try {
    final decoded = jsonDecode(body);

    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String _textOr(Object? value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;
