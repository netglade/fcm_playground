import 'dart:async';
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
/// refuses to start. So does a startup recovery sweep that cannot complete — see
/// `_serve`.
Future<void> main() async {
  final ServerConfig config;
  final TelemetryStore telemetry;
  final RunStore runs;
  try {
    config = ServerConfig.fromEnvironment(
      Platform.environment,
      readFile: (path) => File(path).readAsStringSync(),
    );
    telemetry = _openTelemetry(config.databasePath);
    runs = _openRuns(config.databasePath);
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;

    return;
  }

  try {
    await _serve(config, telemetry, runs);
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}

/// How often the scheduler is asked whether anything is due.
///
/// One second: the countdown on the phone is drawn per second, and a coarser tick
/// would let it reach zero with the send still queued. The scheduler itself owns no
/// timer — this is the only one in the process, and it is why the whole test suite
/// creates none.
const schedulerTickInterval = Duration(seconds: 1);

/// Runs one scheduler tick and keeps whatever it throws from reaching the
/// `unawaited` call in [_serve].
///
/// `SendScheduler._dispatch` already turns a failing send into a `failed` item
/// rather than letting the throw escape, but this is the belt to that braces:
/// an `unawaited` async callback inside `Timer.periodic` that *does* throw takes
/// the whole isolate down with it — verified empirically, not assumed — because
/// a bound listening socket does not keep a crashed isolate alive. Logging and
/// moving on is correct here specifically because every path that matters for
/// correctness already writes its own outcome to the run store before it could
/// reach this point; what lands here is unexpected by definition.
Future<void> _tick(SendScheduler scheduler) async {
  try {
    await scheduler.tick(DateTime.now().toUtc());
  } on Object catch (error, stackTrace) {
    stderr.writeln('scheduler tick failed: $error\n$stackTrace');
  }
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

/// Opens the run store at the same path as the telemetry — one database file to
/// point at, one to back up — and restates whatever `SqliteRunStore.open` throws as
/// a [StateError] naming the path, so it exits 64 like every other configuration
/// mistake rather than as a stack trace.
RunStore _openRuns(String path) {
  try {
    return SqliteRunStore.open(path);
  } on Object catch (error) {
    throw StateError('Could not open the run database at $path: $error');
  }
}

/// Wires the sender, router and HTTP listener together and starts serving.
///
/// [telemetry] and [runs] are held for the life of the process and never closed:
/// this function returns while the listener keeps the isolate alive, so serving has
/// no end code here observes. Nothing is lost, because every `record` commits its
/// own transaction.
Future<void> _serve(
  ServerConfig config,
  TelemetryStore telemetry,
  RunStore runs,
) async {
  final client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(config.serviceAccountJson),
    const [fcmMessagingScope],
  );
  final sender = HttpV1FcmSender(client: client, projectId: config.projectId);

  final scheduler = SendScheduler(
    runs: runs,
    telemetry: telemetry,
    sender: sender,
    // Run ids and trace ids are the same kind of thing: unique across this server
    // and every other.
    newId: newTraceId,
    now: () => DateTime.now().toUtc(),
  );

  // Before the listener, not after: a run that came due while the process was down
  // must be settled before a client can ask what became of it. Restated as a
  // `StateError` on failure so a corrupt sweep exits 64 like every other
  // configuration mistake, rather than crashing `main` with a bare stack trace.
  try {
    await scheduler.recover(DateTime.now().toUtc());
  } on Object catch (error) {
    throw StateError('The startup recovery sweep failed: $error');
  }
  Timer.periodic(schedulerTickInterval, (_) => unawaited(_tick(scheduler)));

  final router = ApiRouter(
    sender: sender,
    now: () => DateTime.now().toUtc(),
    newTraceId: newTraceId,
    telemetry: telemetry,
    scheduler: scheduler,
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
    '(project ${config.projectId}), recording telemetry and scheduled runs in '
    '${config.databasePath}.',
  );
}
