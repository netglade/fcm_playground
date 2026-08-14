import 'dart:convert';

import 'package:path/path.dart' as p;

/// Everything the server reads from its environment, resolved once at startup.
///
/// Every failure here is a [StateError] naming the variable at fault, and the
/// entry point refuses to serve — a missing credential must surface as "the
/// server would not start" rather than as a 500 on somebody's first send.
class ServerConfig {
  /// Creates a config directly. Prefer [ServerConfig.fromEnvironment]; this is
  /// mainly for tests that already have a resolved value.
  const ServerConfig({
    required this.serviceAccountJson,
    required this.projectId,
    required this.port,
    required this.databasePath,
  });

  /// Reads the config from [environment], using [readFile] to load the service
  /// account key.
  ///
  /// [readFile] is a parameter rather than a direct `File(...).readAsStringSync`
  /// so the rules here are testable without touching a disk or holding a real
  /// key.
  factory ServerConfig.fromEnvironment(
    Map<String, String> environment, {
    required String Function(String path) readFile,
  }) {
    final path = environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (path == null || path.trim().isEmpty) {
      throw StateError(
        'GOOGLE_APPLICATION_CREDENTIALS is not set. It must point at a Firebase '
        'service account JSON key — see apps/fcm_api/README.md.',
      );
    }

    final serviceAccountJson = _readServiceAccount(path, readFile);
    final projectId =
        environment['FCM_PROJECT_ID'] ??
        _textOrNull(serviceAccountJson['project_id']);
    if (projectId == null) {
      throw StateError(
        'The key at $path has no "project_id", so set FCM_PROJECT_ID.',
      );
    }

    return ServerConfig(
      serviceAccountJson: serviceAccountJson,
      projectId: projectId,
      port: _readPort(environment['PORT']),
      databasePath: _readDatabasePath(environment['FCM_TELEMETRY_DB'], path),
    );
  }

  /// The service account key, as loaded. Passed straight to
  /// `ServiceAccountCredentials.fromJson`.
  final Map<String, dynamic> serviceAccountJson;

  /// The Firebase project to send through.
  final String projectId;

  /// The loopback port to listen on.
  final int port;

  /// Where the telemetry database lives. Handed to `SqliteTelemetryStore.open`.
  final String databasePath;
}

/// The name of the database file, when the operator has not named one.
const _databaseFileName = 'fcm-telemetry.sqlite';

/// Resolves the telemetry database from `FCM_TELEMETRY_DB`, defaulting to a
/// file beside the service-account key at [keyPath].
///
/// Beside the key deliberately: the two files that must never be committed then
/// live in one directory, so whoever has kept one out of the repository has kept
/// both out.
///
/// A blank explicit value is refused rather than treated as unset. Falling back
/// would put the database somewhere the operator did not ask for, and they would
/// then look for their data in the wrong place — which, for a store that exists
/// to be queried days later, is indistinguishable from having recorded nothing.
String _readDatabasePath(String? value, String keyPath) {
  if (value == null) {
    return p.normalize(p.join(p.dirname(keyPath), _databaseFileName));
  }

  if (value.trim().isEmpty) {
    throw StateError(
      'FCM_TELEMETRY_DB is set but blank. Give it a path to a file, or unset '
      'it to keep the database beside the service account key.',
    );
  }

  return value;
}

/// Loads and decodes the service account key at [path] via [readFile].
///
/// Any read failure and any decode failure both become the same kind of
/// [StateError] — from the operator's chair, an unreadable path and
/// unparsable content are the same problem: the credential is broken.
Map<String, dynamic> _readServiceAccount(
  String path,
  String Function(String path) readFile,
) {
  final String contents;
  try {
    contents = readFile(path);
  } catch (error) {
    // Any read failure is the same problem for the operator: the path is wrong
    // or unreadable. The original error is kept in the message.
    throw StateError('Could not read the service account key at $path: $error');
  }

  try {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('The key at $path is not a JSON object.');
    }

    return decoded;
  } on FormatException catch (error) {
    throw StateError('The key at $path is not valid JSON: ${error.message}');
  }
}

/// Parses `PORT`, defaulting to 8080 when unset.
///
/// A default is safe here because an absent `PORT` is normal (most local
/// runs), while a present-but-invalid one is an operator mistake worth
/// failing loudly on.
int _readPort(String? value) {
  if (value == null) {
    return 8080;
  }

  final port = int.tryParse(value);
  if (port == null) {
    throw StateError('PORT must be a number, got "$value".');
  }

  return port;
}

/// Narrows a decoded JSON value to a non-blank [String], or null.
String? _textOrNull(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
