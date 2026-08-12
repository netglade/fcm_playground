import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

/// Starts the send API on loopback.
///
/// Exits 64 (`EX_USAGE`) on a configuration problem, so a wrong environment is
/// distinguishable from a crash.
Future<void> main() async {
  final ServerConfig config;
  try {
    config = ServerConfig.fromEnvironment(
      Platform.environment,
      readFile: (path) => File(path).readAsStringSync(),
    );
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;

    return;
  }

  await _serve(config);
}

/// Wires the sender, router and HTTP listener together and starts serving.
///
/// Split out of [main] so the configuration failure path above stays short
/// and this half — the part that actually talks to Google and to sockets —
/// is easy to read on its own.
Future<void> _serve(ServerConfig config) async {
  final client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(config.serviceAccountJson),
    const [fcmMessagingScope],
  );

  final router = ApiRouter(
    sender: HttpV1FcmSender(client: client, projectId: config.projectId),
    // Microseconds, so two sends in the same millisecond still differ — the id
    // is what de-duplicates deliveries in the inbox.
    newPayloadId: () => 'api-${DateTime.now().microsecondsSinceEpoch}',
    now: () => DateTime.now().toUtc(),
  );

  final server = await serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(router.handler),
    InternetAddress.loopbackIPv4,
    config.port,
  );

  stdout.writeln(
    'Send API listening on http://${server.address.host}:${server.port} '
    '(project ${config.projectId}).',
  );
}
