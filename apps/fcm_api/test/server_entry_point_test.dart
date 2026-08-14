import 'dart:io';

import 'package:test/test.dart';

import 'sqlite_availability.dart';

void main() {
  // The entry point is run as a real process, because what is under test is an
  // exit code: `exitCode = 64` cannot be observed from inside the isolate that
  // sets it, and `main` is otherwise the one part of this package that no test
  // reaches. Each run costs about a second and a half, measured.
  group('bin/server.dart', _configurationFailures);

  // Opening a database needs the native library, so these skip where it is
  // absent, exactly as the SQLite store's own tests do.
  group(
    'bin/server.dart, given a database path',
    _databaseWiring,
    skip: sqliteAvailability(),
  );
}

/// A key file that parses but is not usable: it carries the `project_id`
/// `ServerConfig` needs and nothing `ServiceAccountCredentials` accepts.
///
/// This is what makes these tests possible without a real credential. The entry
/// point resolves its configuration and opens its database, then dies on the
/// credential with exit 255 — so everything that happens *before* the
/// credential is observable, and 64 means specifically "the configuration was
/// refused" rather than "the process failed".
const _keyJson = '{"type": "service_account", "project_id": "fcm-sandbox"}';

/// The failures that need no database and no temporary files.
void _configurationFailures() {
  test('exits 64 when the credential is not configured', () async {
    final result = await _run(const {'GOOGLE_APPLICATION_CREDENTIALS': ''});

    expect(result, _refuses('GOOGLE_APPLICATION_CREDENTIALS'));
  });
}

/// What the entry point does with the database path its configuration resolved.
void _databaseWiring() {
  late Directory directory;
  late String keyPath;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fcm_api_entry_point_');
    keyPath = '${directory.path}/service-account.json';
    File(keyPath).writeAsStringSync(_keyJson);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  test('creates the database beside the key when none is configured', () async {
    // Proves the default is not merely computed but opened: the file appears in
    // a directory created by this test after the entry point was written, so no
    // fixed path in the code could have produced it.
    final result = await _run({'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

    expect(File('${directory.path}/fcm-telemetry.sqlite').existsSync(), isTrue);
    expect(
      result.exitCode,
      isNot(64),
      reason: 'this configuration was valid; only the credential was not',
    );
  });

  test(
    'opens the database FCM_TELEMETRY_DB names, and only that one',
    () async {
      final databasePath = '${directory.path}/somewhere-else.sqlite';

      await _run({
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'FCM_TELEMETRY_DB': databasePath,
      });

      expect(File(databasePath).existsSync(), isTrue);
      expect(
        File('${directory.path}/fcm-telemetry.sqlite').existsSync(),
        isFalse,
        reason: 'the default must not be opened as well',
      );
    },
  );

  test('exits 64 when the database cannot be opened', () async {
    // The case this task exists for. A server that started and then silently
    // recorded nothing would be worse than one that refuses to start — and
    // `sqlite3.open` throws a `SqliteException`, not the `StateError` the entry
    // point already answers 64 for, so an unwrapped failure would leave a
    // stack trace and exit 255.
    final databasePath = '${directory.path}/no-such-directory/events.sqlite';

    final result = await _run({
      'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
      'FCM_TELEMETRY_DB': databasePath,
    });

    expect(result, _refuses(databasePath));
  });
}

/// Matches a run that refused to serve, naming [reason] and nothing else.
///
/// The absence of a stack trace is half the point: an operator who gets one
/// reads it as a bug in the server rather than as a variable they set wrongly.
Matcher _refuses(String reason) => isA<ProcessResult>()
    .having((result) => result.exitCode, 'exitCode', 64)
    .having((result) => result.stderr, 'stderr', contains(reason))
    .having(
      (result) => result.stderr,
      'stderr',
      isNot(contains('Unhandled exception')),
    );

/// Runs the entry point with exactly [environment] and waits for it to exit.
///
/// The parent environment is deliberately excluded. A developer with
/// `GOOGLE_APPLICATION_CREDENTIALS` or `FCM_TELEMETRY_DB` already exported would
/// otherwise change what these tests are testing, and the unset cases could not
/// be expressed at all. Measured: the VM needs nothing else — the interpreter is
/// named by absolute path, and the package config is found from the script.
Future<ProcessResult> _run(Map<String, String> environment) => Process.run(
  Platform.resolvedExecutable,
  [_serverScript()],
  environment: environment,
  includeParentEnvironment: false,
);

/// The entry point's path, found from wherever the runner was started.
///
/// `melos run ci` runs this suite from the package directory while a direct
/// `fvm dart test apps/fcm_api` runs it from the repo root, so neither literal
/// works on its own.
String _serverScript() {
  for (var directory = Directory.current; ; directory = directory.parent) {
    for (final candidate in [
      '${directory.path}/bin/server.dart',
      '${directory.path}/apps/fcm_api/bin/server.dart',
    ]) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    if (directory.parent.path == directory.path) {
      throw StateError(
        'No apps/fcm_api/bin/server.dart above ${Directory.current.path}.',
      );
    }
  }
}
