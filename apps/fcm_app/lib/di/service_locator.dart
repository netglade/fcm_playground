import 'package:drift_flutter/drift_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../domains/notifications/data_sources/local_notification_presenter.dart';
import '../domains/notifications/data_sources/silent_notification_presenter.dart';
import '../domains/notifications/entities/notification_presenter.dart';
import '../domains/push/data_sources/disabled_push_source.dart';
import '../domains/push/data_sources/firebase_push_source.dart';
import '../domains/push/data_sources/shared_preferences_push_payload_store.dart';
import '../domains/push/entities/push_payload_store.dart';
import '../domains/push/entities/push_source.dart';
import '../domains/push/repositories/push_repository.dart';
import '../domains/runs/data_sources/http_run_scheduler.dart';
import '../domains/runs/data_sources/shared_preferences_active_run_store.dart';
import '../domains/runs/data_sources/unavailable_run_scheduler.dart';
import '../domains/runs/entities/active_run_store.dart';
import '../domains/runs/entities/run_scheduler.dart';
import '../domains/runs/start_run.dart';
import '../domains/sandbox/data_sources/http_notification_sender.dart';
import '../domains/sandbox/data_sources/unavailable_notification_sender.dart';
import '../domains/sandbox/entities/notification_sender.dart';
import '../domains/telemetry/data_sources/drift_telemetry_buffer.dart';
import '../domains/telemetry/data_sources/shared_preferences_device_identity.dart';
import '../domains/telemetry/data_sources/silent_push_telemetry.dart';
import '../domains/telemetry/data_sources/telemetry_reporter.dart';
import '../domains/telemetry/entities/device_identity.dart';
import '../domains/telemetry/entities/push_telemetry.dart';
import '../domains/telemetry/entities/telemetry_buffer.dart';
import '../firebase_options.dart';
import '../firebase_setup.dart';

/// The app's locator, holding only what outlives a page.
///
/// No cubit is ever registered here. A cubit in a locator outlives the page that
/// shows it, carries the previous page's state into the next one, and no test can
/// be given a fresh one without resetting a global. Cubits are created by the
/// widget that owns them; what they are built *from* is what lives here.
final getIt = GetIt.instance;

/// Builds and registers every long-lived collaborator, once, before the first
/// frame.
///
/// [onBackgroundMessage] is passed in rather than named here because the handler
/// runs in its own isolate: it has to be a top-level function in `main.dart` for
/// AOT to keep it reachable, and it cannot see anything registered below.
///
/// [options] and [isWeb] are seams for the tests — one to hand over placeholder
/// credentials and watch the sentinel fall back, the other to check the web
/// decision in [openTelemetryBuffer] from the VM.
Future<void> configureDependencies({
  required BackgroundMessageHandler onBackgroundMessage,
  FirebaseOptions? options,
  bool isWeb = kIsWeb,
}) async {
  final setupError = await _registerPushSource(
    onBackgroundMessage,
    options ?? DefaultFirebaseOptions.currentPlatform,
  );
  final presenter = await _startPresenter();
  getIt
    ..registerSingleton<PushPayloadStore>(SharedPreferencesPushPayloadStore())
    ..registerSingleton<DeviceIdentity>(SharedPreferencesDeviceIdentity())
    ..registerSingleton<ActiveRunStore>(SharedPreferencesActiveRunStore())
    ..registerSingleton<NotificationPresenter>(presenter)
    ..registerSingleton<NotificationSender>(_senderFor(setupError))
    ..registerSingleton<RunScheduler>(_runSchedulerFor(setupError));
  getIt.registerSingleton<StartRun>(
    StartRun(scheduler: getIt<RunScheduler>(), active: getIt<ActiveRunStore>()),
  );
  _registerTelemetry(isWeb: isWeb);
  // A singleton necessarily: the repository owns the push subscription and the
  // token, so a second instance would subscribe twice to a single-subscription
  // stream — which throws — and leave the app with two inboxes that disagree.
  getIt.registerSingleton<PushRepository>(
    PushRepository(
      getIt<PushSource>(),
      store: getIt<PushPayloadStore>(),
      presenter: getIt<NotificationPresenter>(),
      // The same reporter the sandbox sends through, so a `not_received` and the
      // `sent` it contradicts land in one buffer and one database.
      telemetry: getIt<PushTelemetry>(),
      setupError: setupError,
    ),
  );
}

/// Opens the on-device event buffer, or null where there is none.
///
/// Public because the background isolate needs the same construction and cannot
/// reach [getIt]: both sides have to name the same file, since a `received_bg`
/// written to one database and flushed from another would never be sent.
///
/// Null on web deliberately. `drift_flutter`'s web path throws `ArgumentError`
/// *synchronously* without a `web:` argument naming a `sqlite3.wasm` and a worker,
/// so the build compiles and then dies at startup. This app cannot receive a push
/// on web without a VAPID key anyway.
DriftTelemetryBuffer? openTelemetryBuffer({bool isWeb = kIsWeb}) =>
    isWeb ? null : DriftTelemetryBuffer(driftDatabase(name: 'fcm_telemetry'));

/// The reporter over [buffer] for the install [identity] names.
///
/// The identity is a parameter rather than a lookup so the background isolate can
/// pass its own: nothing is registered in that isolate's locator.
TelemetryReporter telemetryReporterOn(
  TelemetryBuffer buffer,
  DeviceIdentity identity,
) => TelemetryReporter(
  buffer: buffer,
  identity: identity,
  baseUrl: Uri.parse(defaultApiBaseUrl),
);

/// Registers the buffer and the telemetry hook, or silence where there is no
/// buffer.
///
/// `TelemetryBuffer` is left unregistered rather than given a do-nothing stand-in:
/// every hook already treats telemetry as optional through [PushTelemetry], so
/// silence belongs at that seam.
void _registerTelemetry({required bool isWeb}) {
  final buffer = openTelemetryBuffer(isWeb: isWeb);
  if (buffer == null) {
    getIt.registerSingleton<PushTelemetry>(const SilentPushTelemetry());

    return;
  }

  getIt
    ..registerSingleton<TelemetryBuffer>(buffer)
    ..registerSingleton<PushTelemetry>(
      telemetryReporterOn(buffer, getIt<DeviceIdentity>()),
    );
}

/// Registers the live [PushSource], or a disabled one, answering why.
///
/// Conditional, never eager: a fresh clone still holds the placeholder
/// credentials, and registering a `FirebasePushSource` regardless would crash at
/// startup instead of opening and explaining what to run.
Future<String?> _registerPushSource(
  BackgroundMessageHandler onBackgroundMessage,
  FirebaseOptions options,
) async {
  PushSource source = const DisabledPushSource();
  String? setupError;
  try {
    source = await _startPushSource(onBackgroundMessage, options);
  } catch (error) {
    setupError = '$error';
  }
  getIt.registerSingleton<PushSource>(source);

  return setupError;
}

/// Starts Firebase and returns a live [PushSource].
///
/// Throws [StateError] while `firebase_options.dart` still holds placeholder
/// credentials. The project id is real, so the API key is what gets checked —
/// initialising with a fake key fails later with a far less useful message.
Future<PushSource> _startPushSource(
  BackgroundMessageHandler onBackgroundMessage,
  FirebaseOptions options,
) async {
  if (options.apiKey == unconfiguredApiKey) {
    throw StateError(firebaseSetupInstructions);
  }

  await Firebase.initializeApp(options: options);
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

  final source = FirebasePushSource(FirebaseMessaging.instance);
  await source.requestPermission();
  await source.start();

  return source;
}

/// Starts local notifications, degrading to silence rather than failing: a broken
/// plugin should cost the banners, not the app.
Future<NotificationPresenter> _startPresenter() async {
  final presenter = LocalNotificationPresenter();
  try {
    await presenter.initialize();

    return presenter;
  } catch (error) {
    debugPrint('Local notifications are unavailable: $error');
    await presenter.dispose();

    return const SilentNotificationPresenter();
  }
}

NotificationSender _senderFor(String? setupError) => setupError == null
    ? HttpNotificationSender(
        client: http.Client(),
        baseUrl: Uri.parse(defaultApiBaseUrl),
      )
    : UnavailableNotificationSender(setupError);

RunScheduler _runSchedulerFor(String? setupError) => setupError == null
    ? HttpRunScheduler(
        client: http.Client(),
        baseUrl: Uri.parse(defaultApiBaseUrl),
      )
    : UnavailableRunScheduler(setupError);
