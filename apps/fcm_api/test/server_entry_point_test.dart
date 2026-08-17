import 'dart:io';

import 'package:test/test.dart';

import 'sqlite_availability.dart';

void main() {
  // Run as a real process, because `exitCode = 64` cannot be observed from inside
  // the isolate that sets it. Each run costs about a second and a half.
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
/// The entry point resolves its configuration and opens its database, then dies on
/// the credential with exit 255 — so everything before the credential is observable,
/// and 64 means "the configuration was refused" rather than "the process failed".
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
    // Proves the default is opened rather than merely computed: the directory is
    // created by this test, so no fixed path in the code could have produced it.
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
    // A server that started and then silently recorded nothing would be worse than
    // one that refuses to start — and `sqlite3.open` throws a `SqliteException`, not
    // the `StateError` the entry point answers 64 for.
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
/// The parent environment is deliberately excluded: a developer with
/// `GOOGLE_APPLICATION_CREDENTIALS` already exported would change what these tests
/// test, and the unset cases could not be expressed at all.
Future<ProcessResult> _run(Map<String, String> environment) => Process.run(
  Platform.resolvedExecutable,
  [_serverScript()],
  environment: environment,
  includeParentEnvironment: false,
);

/// Found from wherever the runner was started: `melos run ci` runs this suite from
/// the package directory, a direct `fvm dart test apps/fcm_api` from the repo root.
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
