import 'dart:async';
import 'dart:io';

import 'package:fcm_app/app.dart';
import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/notifications/entities/notification_presenter.dart';
import 'package:fcm_app/domains/push/entities/push_source.dart';
import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/domains/sandbox/http_notification_sender.dart';
import 'package:fcm_app/domains/telemetry/data_sources/drift_telemetry_buffer.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_buffer.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glade_forms/glade_forms.dart';
import 'package:patrol/patrol.dart';

/// How long FCM registration is given before the run is called a setup failure.
///
/// Starting a test before the token exists is the likeliest source of flake here: the
/// Sandbox disables Send without one, so the test would tap a dead button and fail
/// somewhere far from the cause.
const _tokenTimeout = Duration(seconds: 45);

/// How long the system permission dialog is waited for, on the first launch in
/// this process.
///
/// Patrol launches the app once per target and reuses that isolate for every test
/// in the file, so the dialog is a property of the *process*, not of each test —
/// there is no Test Orchestrator here to clear app data between tests (see the
/// build.gradle.kts comment by `clearPackageData`'s old home), so
/// POST_NOTIFICATIONS is granted once and stays granted. [_firstLaunchInProcess]
/// is what makes [launchApp] wait the full window only the first time; every
/// later launch gates on that flag instead of burning the same fifteen seconds
/// against a dialog that cannot reappear. Bounded rather than required even on
/// the first launch, in case a device or an API level below 33 never shows one.
const _permissionDialogTimeout = Duration(seconds: 15);

/// Whether the app has not yet been launched in this process.
///
/// Library-level rather than a parameter: every `patrolTest` in a group file
/// calls [launchApp] independently, with no shared object across them to hold it
/// on. Set to false the first time the permission dialog is checked for, and
/// never reset — there is one process per target, and the dialog cannot come
/// back within it.
bool _firstLaunchInProcess = true;

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

  await _tearDownPreviousLaunch();
  await getIt.reset();
  GladeForms.initialize();

  // Deliberately not awaited yet. `configureDependencies` awaits
  // `PushSource.requestPermission()`, which on Android 13+ blocks on the system
  // POST_NOTIFICATIONS dialog — so awaiting it before granting would deadlock the
  // test against a dialog only native automation can dismiss.
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

  // The same two channels `main.dart` wires, for the same reason: FCM reports taps on
  // the tray entries it drew, the presenter reports taps on the banners the app drew.
  getIt<PushSource>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().dismissals.listen(repository.reportDismissed);

  // Pinned rather than inherited, and deliberately NOT mirroring main.dart's
  // read-the-stored-preference block: every finder in this suite is English copy, so
  // the suite has to run in English regardless of what the handset or a previous
  // manual walkthrough left behind. Without this it passes only by accident — slang
  // starts on the base locale and nothing here tells it otherwise.
  LocaleSettings.setLocaleSync(AppLocale.en);

  // `pumpWidget` then `pumpAndTrySettle` rather than the one-shot
  // `pumpWidgetAndSettle`: `AppShell`'s `IndexedStack` builds `TelemetryView` at
  // launch, whose cubit immediately calls an unbounded `GET /latency`, and a
  // spinner keeps frames scheduled for as long as that takes. A strict settle
  // throws after its own timeout rather than tolerating a still-busy frame, so
  // once the telemetry database is large enough every test would fail right here
  // with a bare "pumpAndSettle timed out" and no hint that the remedy is deleting
  // the database.
  //
  // Wrapped in TranslationProvider for the same reason main.dart wraps runApp with
  // it: App.build reads TranslationProvider.of(context), which throws
  // 'Please wrap your app with "TranslationProvider".' with no ancestor to find.
  // The LocaleSettings pin above decides which language; this is the separate,
  // equally required piece that lets App read any language at all.
  await $.pumpWidget(TranslationProvider(child: const App()));
  await $.pumpAndTrySettle();
  await _waitForToken($);
}

/// Disposes what the previous launch registered, before [getIt]'s own reset
/// drops the registrations without disposing them.
///
/// Patrol launches the app once per target and reuses that isolate for every
/// test in the file, so without this a fifth test in a group file leaves five
/// `PushRepository`s subscribed to the same broadcast, five presenters, and five
/// open connections to one telemetry database — every arrival ingested, drawn
/// and written that many times over. `GetIt.reset()` only disposes a
/// registration made with a `dispose:` callback or one implementing
/// `Disposable`; `configureDependencies` registers all of these bare. Guarded by
/// `isRegistered`, so the very first launch — nothing registered yet — is a
/// no-op.
Future<void> _tearDownPreviousLaunch() async {
  if (getIt.isRegistered<PushRepository>()) {
    getIt<PushRepository>().dispose();
  }
  if (getIt.isRegistered<NotificationPresenter>()) {
    await getIt<NotificationPresenter>().dispose();
  }
  // `TelemetryBuffer` is only ever registered as a `DriftTelemetryBuffer` — see
  // `_registerTelemetry` — but the interface itself declares no `close`, so the
  // concrete type has to be named here to reach it.
  if (getIt.isRegistered<TelemetryBuffer>()) {
    final buffer = getIt<TelemetryBuffer>();
    if (buffer is DriftTelemetryBuffer) {
      await buffer.close();
    }
  }
}

/// Fails once, legibly, when the local API is not running.
///
/// Without this the suite produces twenty-six delivery timeouts whose single cause is
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
/// A no-op: the suite never backgrounds the app, because doing so suspends the very
/// isolate the test runs in. It exists to satisfy the signature, and is annotated
/// because the real one has to be.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async =>
    Future.value();
