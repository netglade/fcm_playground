import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

/// Starts the send API on loopback.
///
/// Exits 64 (`EX_USAGE`) on a configuration problem, so a wrong environment is
/// distinguishable from a crash. An unopenable telemetry database counts as one:
/// a server that starts and then silently records nothing is worse than one that
/// refuses to start, because the gap only shows up later as pushes that look
/// undelivered.
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

/// Opens the telemetry database, restating any failure as a [StateError].
///
/// `sqlite3.open` throws a `SqliteException` for a directory that does not exist
/// or a file it may not write — and the `CREATE TABLE` behind this call is what
/// makes an unwritable file fail here rather than on the first send. Neither is
/// a [StateError], so without this the operator gets a stack trace and exit 255
/// for what is really the same class of mistake as a wrong key path.
TelemetryStore _openTelemetry(String path) {
  try {
    return SqliteTelemetryStore.open(path);
  } on Object catch (error) {
    throw StateError('Could not open the telemetry database at $path: $error');
  }
}

/// Wires the sender, router and HTTP listener together and starts serving.
///
/// Split out of [main] so the configuration failure path above stays short
/// and this half — the part that actually talks to Google and to sockets —
/// is easy to read on its own.
///
/// [telemetry] is held for the life of the process and never closed. There is no
/// clean place to close it: this function returns while the listener keeps the
/// isolate alive, so serving has no end that code here observes — the process
/// goes away when it is signalled or killed. Nothing is lost by that, because
/// every `record` commits its own transaction, so an unclosed database has no
/// pending writes. A signal handler could be added, but it would trade that for
/// changing how the server exits, in the one file no test covers.
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

  // The database path is printed because it is the one piece of configuration
  // with a default the operator did not type, and the place they will go looking
  // for the events afterwards.
  stdout.writeln(
    'Send API listening on http://${server.address.host}:${server.port} '
    '(project ${config.projectId}), recording telemetry in '
    '${config.databasePath}.',
  );
}
