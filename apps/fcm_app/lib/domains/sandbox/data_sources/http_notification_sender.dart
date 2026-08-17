import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

import '../entities/notification_send_exception.dart';
import '../entities/notification_sender.dart';

/// Where the send API is expected to be.
///
/// Overridden at build time with `--dart-define=FCM_API_BASE_URL=…`. The default
/// works on a physical device once `adb reverse tcp:8080 tcp:8080` is running,
/// and on the Android emulator it must be pointed at `http://10.0.2.2:8080`.
const defaultApiBaseUrl = String.fromEnvironment(
  'FCM_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Talks to `POST /send` on the local API.
class HttpNotificationSender implements NotificationSender {
  HttpNotificationSender({required this._client, required this._baseUrl});

  final http.Client _client;
  final Uri _baseUrl;

  @override
  Future<SendMessageResponse> send(SendMessageRequest request) async {
    final http.Response response;
    try {
      response = await _client.post(
        _baseUrl.replace(path: '/send'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (error) {
      // The usual cause is a forgotten port forward, so the remedy goes in the
      // message rather than the exception type.
      throw NotificationSendException(
        'Could not reach $_baseUrl — is the API running?\n'
        'On a physical device, run: adb reverse tcp:8080 tcp:8080\n'
        '($error)',
      );
    }

    if (response.statusCode != 200) {
      throw NotificationSendException.fromApiError(_errorFrom(response));
    }

    try {
      return SendMessageResponse.fromJson(_decodeObject(response.body));
    } on FormatException catch (error) {
      throw NotificationSendException(
        'The API answered 200 with something unreadable: ${error.message}',
      );
    }
  }
}

/// Reads the server's `ApiError`, falling back to the status code when the body
/// is not one — a proxy or a crash can answer with anything.
ApiError _errorFrom(http.Response response) {
  try {
    return ApiError.fromJson(_decodeObject(response.body));
  } on FormatException {
    return ApiError(
      'The API answered ${response.statusCode}: ${response.body}',
    );
  }
}

Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Expected a JSON object, got ${decoded.runtimeType}');
  }

  return decoded;
}
