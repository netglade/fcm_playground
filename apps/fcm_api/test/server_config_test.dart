import 'dart:convert';
import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:test/test.dart';

void main() {
  const keyPath = '/keys/service-account.json';
  final keyJson = jsonEncode({
    'type': 'service_account',
    'project_id': 'your-project-id',
    'client_email': 'sender@your-project-id.iam.gserviceaccount.com',
    'private_key': '-----BEGIN PRIVATE KEY-----\nnot-a-real-key\n',
  });

  ServerConfig read(
    Map<String, String> environment, {
    String? fileContents,
    Object? fileError,
  }) => ServerConfig.fromEnvironment(
    environment,
    readFile: (path) {
      if (fileError != null) {
        throw fileError;
      }

      return fileContents ?? keyJson;
    },
  );

  group('ServerConfig.fromEnvironment', () {
    test('reads the service account from GOOGLE_APPLICATION_CREDENTIALS', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.serviceAccountJson['client_email'], isNotNull);
    });

    test('defaults the project id to the key\'s own project', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.projectId, 'your-project-id');
    });

    test('lets FCM_PROJECT_ID override it', () {
      final config = read(const {
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'FCM_PROJECT_ID': 'other-project',
      });

      expect(config.projectId, 'other-project');
    });

    test('defaults the port to 8080', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.port, 8080);
    });

    test('reads PORT when it is set', () {
      final config = read(const {
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'PORT': '9000',
      });

      expect(config.port, 9000);
    });

    test('defaults the database beside the service-account key', () {
      // The two files that must not be committed then live together, so an
      // operator who has excluded one directory has excluded both.
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.databasePath, '/keys/fcm-telemetry.sqlite');
    });

    test('follows the key wherever it lives, rather than one fixed place', () {
      // No single literal satisfies all four of these, which the test above alone
      // would allow. The last two pin that a relative key stays relative.
      final expected = {
        keyPath: '/keys/fcm-telemetry.sqlite',
        '/home/dev/secrets/fcm-key.json':
            '/home/dev/secrets/fcm-telemetry.sqlite',
        'secrets/sa.json': 'secrets/fcm-telemetry.sqlite',
        'sa.json': 'fcm-telemetry.sqlite',
      };

      for (final MapEntry(key: path, value: database) in expected.entries) {
        final config = read({'GOOGLE_APPLICATION_CREDENTIALS': path});

        expect(config.databasePath, database, reason: 'key at $path');
      }
    });

    test('lets FCM_TELEMETRY_DB override it', () {
      final config = read(const {
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'FCM_TELEMETRY_DB': '/var/lib/fcm/events.sqlite',
      });

      expect(config.databasePath, '/var/lib/fcm/events.sqlite');
    });

    test('refuses a blank FCM_TELEMETRY_DB rather than falling back', () {
      // Falling back would put the database somewhere the operator did not ask
      // for, and they would look for their data in the wrong place.
      expect(
        () => read(const {
          'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
          'FCM_TELEMETRY_DB': '  ',
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('FCM_TELEMETRY_DB'),
          ),
        ),
      );
    });

    test('refuses to start without a credential, saying which variable', () {
      expect(
        () => read(const {}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_APPLICATION_CREDENTIALS'),
          ),
        ),
      );
    });

    test(
      'refuses to start when the key file cannot be read, saying the path',
      () {
        const environment = {'GOOGLE_APPLICATION_CREDENTIALS': keyPath};
        expect(
          () => read(
            environment,
            fileError: const FileSystemException('no such file'),
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(keyPath),
            ),
          ),
        );
      },
    );

    test('refuses to start when the key file is not JSON', () {
      const environment = {'GOOGLE_APPLICATION_CREDENTIALS': keyPath};
      expect(() => read(environment, fileContents: 'nope'), throwsStateError);
    });

    test('refuses to start when the key has no project and none is given', () {
      const environment = {'GOOGLE_APPLICATION_CREDENTIALS': keyPath};
      expect(
        () => read(
          environment,
          fileContents: jsonEncode({'type': 'service_account'}),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('FCM_PROJECT_ID'),
          ),
        ),
      );
    });

    test('refuses to start when PORT is not a number', () {
      expect(
        () => read(const {
          'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
          'PORT': 'eight thousand',
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('PORT'),
          ),
        ),
      );
    });
  });
}
