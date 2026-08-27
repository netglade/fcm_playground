import 'dart:async';
import 'dart:io';

import 'package:fcm_app/app.dart';
import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/notifications/notification_presenter.dart';
import 'package:fcm_app/domains/push/push_source.dart';
import 'package:fcm_app/domains/push/push_repository.dart';
import 'package:fcm_app/domains/sandbox/http_notification_sender.dart';
import 'package:fcm_app/domains/telemetry/drift_telemetry_buffer.dart';
import 'package:fcm_app/domains/telemetry/telemetry_buffer.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glade_forms/glade_forms.dart';
import 'package:patrol/patrol.dart';

/// How long FCM registration is given before the run is a setup failure.
///
/// The likeliest source of flake: without a token the Sandbox disables Send, so
/// the test taps a dead button and fails far from the cause.
const _tokenTimeout = Duration(seconds: 45);

/// How long the system permission dialog is waited for, on the first launch in
/// this process.
///
/// Patrol reuses one isolate for every test in a file, so the dialog belongs to the
/// *process*: POST_NOTIFICATIONS is granted once and stays granted.
/// [_firstLaunchInProcess] is what stops every later launch burning the same
/// fifteen seconds. Bounded rather than required, in case a device or an API level
/// below 33 never shows one.
const _permissionDialogTimeout = Duration(seconds: 15);

/// Whether the app has not yet been launched in this process.
///
/// Library-level because each `patrolTest` calls [launchApp] independently, with no
/// shared object to hold it. Never reset — one process per target, and the dialog
/// cannot reappear within it.
bool _firstLaunchInProcess = true;

/// How long a TCP connect to a new host is given before it is called unreachable.
///
/// Only bounds the connect itself: the SDK documents `HttpClient.connectionTimeout`
/// as covering the act of reaching a new host, not anything that happens after.
const _connectTimeout = Duration(seconds: 3);

/// How long the whole `/health` round trip is given before an API that accepted
/// the connection but never answered is called stuck.
///
/// Longer than [_connectTimeout] on purpose: a host can accept a connection and
/// then never write a response, which `connectionTimeout` does not catch.
const _healthCheckTimeout = Duration(seconds: 5);

/// Brings the real app up, ready to drive.
///
/// Mirrors `main.dart` rather than calling it, because startup has to interleave
/// with native automation. The stream wiring below is what makes `opened` and
/// `dismissed` observable at all.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await requireApiReachable();

  await _tearDownPreviousLaunch();
  await getIt.reset();
  GladeForms.initialize();

  // Not awaited yet: `configureDependencies` awaits `requestPermission()`, which
  // on Android 13+ blocks on the system dialog — awaiting it before granting
  // deadlocks the test against a dialog only native automation can dismiss.
  final configured = configureDependencies(
    onBackgroundMessage: _onBackgroundMessage,
  );
  final dialogTimeout = _firstLaunchInProcess
      ? _permissionDialogTimeout
      : Duration.zero;
  if (await $.platformAutomator.mobile.isPermissionDialogVisible(
    timeout: dialogTimeout,
  )) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
  }
  _firstLaunchInProcess = false;
  await configured;

  final repository = getIt<PushRepository>()..listen();
  await repository.restore();
  await repository.refreshToken();

  // The same two channels `main.dart` wires, for the same reason.
  getIt<PushSource>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().dismissals.listen(repository.reportDismissed);

  // Pinned, and deliberately not mirroring main.dart's stored-preference block:
  // every finder here is English copy, so the suite must run in English whatever
  // the handset was left on.
  LocaleSettings.setLocaleSync(AppLocale.en);

  // `pumpWidget` then `pumpAndTrySettle`, not the one-shot
  // `pumpWidgetAndSettle`: `TelemetryView` is built at launch and its cubit calls
  // an unbounded `GET /latency`, whose spinner keeps frames scheduled. A strict
  // settle would fail every test with a bare "pumpAndSettle timed out" once the
  // telemetry database grew, never hinting that deleting it is the remedy.
  //
  // TranslationProvider for the reason main.dart wraps runApp in it: App.build
  // reads it and throws without an ancestor. The pin above chooses the language;
  // this lets App read any at all.
  await $.pumpWidget(TranslationProvider(child: const App()));
  await $.pumpAndTrySettle();
  await _waitForToken($);
}

/// Disposes what the previous launch registered, before [getIt]'s reset drops the
/// registrations without disposing them.
///
/// One isolate serves every test in a file, so without this the fifth test leaves
/// five `PushRepository`s on one broadcast, five presenters and five connections to
/// one database — every arrival ingested, drawn and written five times.
/// `GetIt.reset()` disposes only registrations made with `dispose:` or
/// `Disposable`, and these are all registered bare.
Future<void> _tearDownPreviousLaunch() async {
  if (getIt.isRegistered<PushRepository>()) {
    getIt<PushRepository>().dispose();
  }
  if (getIt.isRegistered<NotificationPresenter>()) {
    await getIt<NotificationPresenter>().dispose();
  }
  // Always registered as a `DriftTelemetryBuffer`, but the interface declares no
  // `close`, so the concrete type has to be named to reach it.
  if (getIt.isRegistered<TelemetryBuffer>()) {
    final buffer = getIt<TelemetryBuffer>();
    if (buffer is DriftTelemetryBuffer) {
      await buffer.close();
    }
  }
}

/// Fails once, legibly, when the local API is not running.
///
/// Without it, one stopped process becomes thirty-six delivery timeouts, and the
/// first one read sends someone into the app.
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
    client.close(force: true);
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
  await $('Registration token').waitUntilVisible(timeout: _tokenTimeout);
}

/// The background handler `configureDependencies` requires.
///
/// A no-op — backgrounding the app would suspend the isolate the test runs in. It
/// exists for the signature, and is annotated because the real one must be.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async =>
    Future.value();
