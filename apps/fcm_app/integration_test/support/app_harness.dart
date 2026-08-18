import 'dart:async';
import 'dart:io';

import 'package:fcm_app/app.dart';
import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/notifications/entities/notification_presenter.dart';
import 'package:fcm_app/domains/push/entities/push_source.dart';
import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/domains/sandbox/data_sources/http_notification_sender.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glade_forms/glade_forms.dart';
import 'package:patrol/patrol.dart';

/// How long FCM registration is given before the run is called a setup failure.
///
/// Starting a test before the token exists is the likeliest source of flake here: the
/// Sandbox disables Send without one, so the test would tap a dead button and fail
/// somewhere far from the cause.
const tokenTimeout = Duration(seconds: 45);

/// How long the system permission dialog is waited for.
///
/// `clearPackageData` revokes POST_NOTIFICATIONS between tests, so the dialog is
/// expected every time; the wait is bounded rather than required in case a device or
/// an API level below 33 never shows one.
const _permissionDialogTimeout = Duration(seconds: 15);

/// How long a TCP connect to a new host is given before it is called unreachable.
///
/// Only bounds the connect itself: the SDK documents `HttpClient.connectionTimeout`
/// as covering the act of reaching a new host, not anything that happens after.
const _connectTimeout = Duration(seconds: 3);

/// How long the whole `/health` round trip — connect, headers and body — is given
/// before an API that accepted the connection but never answered is called stuck.
///
/// A separate, longer bound than [_connectTimeout] on purpose: a host can accept a
/// TCP connection and then never write a response, which `connectionTimeout` alone
/// does not catch.
const _healthCheckTimeout = Duration(seconds: 5);

/// Brings the real app up, ready to drive.
///
/// Mirrors `main.dart` rather than calling it: `main` is not callable from a test that
/// has to interleave native automation with startup, and the stream wiring below is
/// the part that makes `opened` and `dismissed` reachable at all — a harness that
/// skipped it would quietly make those two events unobservable.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await requireApiReachable();

  await getIt.reset();
  GladeForms.initialize();

  // Deliberately not awaited yet. `configureDependencies` awaits
  // `PushSource.requestPermission()`, which on Android 13+ blocks on the system
  // POST_NOTIFICATIONS dialog — so awaiting it before granting would deadlock the
  // test against a dialog only native automation can dismiss.
  final configured = configureDependencies(
    onBackgroundMessage: _onBackgroundMessage,
  );
  if (await $.platformAutomator.mobile.isPermissionDialogVisible(
    timeout: _permissionDialogTimeout,
  )) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
  }
  await configured;

  final repository = getIt<PushRepository>()..listen();
  await repository.restore();
  await repository.refreshToken();

  // The same two channels `main.dart` wires, for the same reason: FCM reports taps on
  // the tray entries it drew, the presenter reports taps on the banners the app drew.
  getIt<PushSource>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from),
  );
  getIt<NotificationPresenter>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from),
  );
  getIt<NotificationPresenter>().dismissals.listen(repository.reportDismissed);

  await $.pumpWidgetAndSettle(const App());
  await _waitForToken($);
}

/// Fails once, legibly, when the local API is not running.
///
/// Without this the suite produces seventeen delivery timeouts whose single cause is
/// one stopped process, and the first one read would send someone into the app.
Future<void> requireApiReachable() async {
  final Uri healthUri;
  try {
    healthUri = Uri.parse(defaultApiBaseUrl).replace(path: '/health');
  } on FormatException catch (error) {
    throw StateError(
      'FCM_API_BASE_URL="$defaultApiBaseUrl" is not a valid URL ($error).',
    );
  }

  final client = HttpClient()..connectionTimeout = _connectTimeout;
  try {
    final response = await _fetchHealth(
      client,
      healthUri,
    ).timeout(_healthCheckTimeout);
    if (response.statusCode != 200) {
      throw StateError(
        'The API at $defaultApiBaseUrl answered ${response.statusCode} for '
        '/health. Start it with: melos run api:serve',
      );
    }
  } on SocketException catch (error) {
    throw StateError(
      'Could not reach the API at $defaultApiBaseUrl ($error).\n'
      'Start it with: melos run api:serve\n'
      'On a physical handset also run: adb reverse tcp:8080 tcp:8080\n'
      'On the emulator rebuild with '
      '--dart-define=FCM_API_BASE_URL=http://10.0.2.2:8080',
    );
  } on TimeoutException {
    throw StateError(
      'The API at $defaultApiBaseUrl accepted a connection but did not answer '
      '/health within $_healthCheckTimeout. Start it with: melos run api:serve',
    );
  } finally {
    client.close();
  }
}

/// The connect-headers-body sequence `requireApiReachable` bounds as one whole.
Future<HttpClientResponse> _fetchHealth(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  await response.drain<void>();

  return response;
}

/// Waits on the Inbox — the shell's default destination — until the token is drawn.
Future<void> _waitForToken(PatrolIntegrationTester $) async {
  await $('Push inbox').waitUntilVisible();
  await $('Registration token').waitUntilVisible(timeout: tokenTimeout);
}

/// The background handler `configureDependencies` requires.
///
/// A no-op: the suite never backgrounds the app, because doing so suspends the very
/// isolate the test runs in. It exists to satisfy the signature, and is annotated
/// because the real one has to be.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async =>
    Future.value();
