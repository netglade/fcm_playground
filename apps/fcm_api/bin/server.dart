import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

/// Starts the send API on loopback.
///
/// Exits 64 (`EX_USAGE`) on a configuration problem, so a wrong environment is
/// distinguishable from a crash. An unopenable telemetry database counts as one: a
/// server that starts and then silently records nothing is worse than one that
/// refuses to start.
Future<void> main() async {
  final ServerConfig config;
  final TelemetryStore telemetry;
  try {
    config = ServerConfig.fromEnvironment(
      Platform.environment,
      readFile: (path) => File(path).readAsStringSync(),
    );
    telemetry = _openTelemetry(config.databasePath);
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;

    return;
  }

  await _serve(config, telemetry);
}

/// Restates a `SqliteException` as a [StateError], so an unwritable database path
/// exits 64 like every other configuration mistake rather than as a stack trace.
TelemetryStore _openTelemetry(String path) {
  try {
    return SqliteTelemetryStore.open(path);
  } on Object catch (error) {
    throw StateError('Could not open the telemetry database at $path: $error');
  }
}

/// Wires the sender, router and HTTP listener together and starts serving.
///
/// [telemetry] is held for the life of the process and never closed: this function
/// returns while the listener keeps the isolate alive, so serving has no end code
/// here observes. Nothing is lost, because every `record` commits its own
/// transaction.
Future<void> _serve(ServerConfig config, TelemetryStore telemetry) async {
  final client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(config.serviceAccountJson),
    const [fcmMessagingScope],
  );

  final router = ApiRouter(
    sender: HttpV1FcmSender(client: client, projectId: config.projectId),
    now: () => DateTime.now().toUtc(),
    newTraceId: newTraceId,
    telemetry: telemetry,
  );

  final server = await serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(router.handler),
    InternetAddress.loopbackIPv4,
    config.port,
  );

  // The database path is printed because it is the one piece of configuration with
  // a default the operator did not type.
  stdout.writeln(
    'Send API listening on http://${server.address.host}:${server.port} '
    '(project ${config.projectId}), recording telemetry in '
    '${config.databasePath}.',
  );
}
