import 'package:drift_flutter/drift_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../firebase_setup.dart';
import '../notifications/local_notification_presenter.dart';
import '../notifications/notification_presenter.dart';
import '../notifications/silent_notification_presenter.dart';
import '../push/disabled_push_source.dart';
import '../push/firebase_push_source.dart';
import '../push/push_payload_store.dart';
import '../push/push_repository.dart';
import '../push/push_source.dart';
import '../push/shared_preferences_push_payload_store.dart';
import '../sandbox/http_notification_sender.dart';
import '../sandbox/notification_sender.dart';
import '../sandbox/unavailable_notification_sender.dart';
import '../telemetry/device_identity.dart';
import '../telemetry/drift_telemetry_buffer.dart';
import '../telemetry/push_telemetry.dart';
import '../telemetry/shared_preferences_device_identity.dart';
import '../telemetry/silent_push_telemetry.dart';
import '../telemetry/telemetry_buffer.dart';
import '../telemetry/telemetry_reporter.dart';

/// The app's locator, holding only what outlives a page.
///
/// **No cubit is ever registered here.** A cubit in a locator is a singleton
/// pretending to be page state: it outlives the page that shows it, carries the
/// previous page's state into the next one, and no test can be given a fresh one
/// without resetting a global. Cubits are created by the widget that owns them
/// and reach the tree through `BlocProvider`; what they are built *from* is what
/// lives here.
final getIt = GetIt.instance;

/// Builds and registers every long-lived collaborator, once, before the first
/// frame.
///
/// [onBackgroundMessage] is passed in rather than named here because the handler
/// runs in its own isolate: it has to be a top-level function in `main.dart` for
/// AOT to keep it reachable, and it cannot see anything registered below.
///
/// Two seams exist for the tests, and production passes neither. [options]
/// defaults to the generated credentials, so a test can hand over ones still
/// carrying the placeholder key and watch the sentinel fall back — which this
/// checkout's real credentials no longer trigger. [isWeb] defaults to the real
/// platform flag, so the web decision in [openTelemetryBuffer] can be checked
/// from the VM, where there is no other way to reach it.
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
    ..registerSingleton<NotificationPresenter>(presenter)
    // Sending needs the same registration token the repository listens with, so
    // there is no separate "is sending available" question to answer here.
    ..registerSingleton<NotificationSender>(_senderFor(setupError));
  _registerTelemetry(isWeb: isWeb);
  // A singleton, and this is the one registration that could not be anything
  // else: the repository owns the push subscription and the token, so a second
  // instance would subscribe a second time to a single-subscription stream —
  // which throws — and leave the app with two inboxes that disagree.
  getIt.registerSingleton<PushRepository>(
    PushRepository(
      getIt<PushSource>(),
      store: getIt<PushPayloadStore>(),
      presenter: getIt<NotificationPresenter>(),
      // The same reporter the sandbox sends through, so a `not_received` and
      // the `sent` it contradicts land in one buffer and one database.
      telemetry: getIt<PushTelemetry>(),
      setupError: setupError,
    ),
  );
}

/// Opens the on-device event buffer, or null where there is none.
///
/// Public because the background isolate needs the same construction and cannot
/// reach [getIt]: the foreground and the background have to name the same file,
/// since a `received_bg` written to one database and flushed from another would
/// never be sent.
///
/// **Null on web, and this is not a shortcut.** `drift_flutter`'s web path
/// requires a `web:` argument naming a `sqlite3.wasm` and a drift worker, and
/// throws `ArgumentError` *synchronously* without one — so the web build compiles
/// and then dies at startup, which `flutter build web --release` cannot catch
/// because it only compiles. Rather than ship those assets: this app cannot
/// receive a push on web at all without a VAPID key, so there is nothing on web
/// for a telemetry buffer to hold.
DriftTelemetryBuffer? openTelemetryBuffer({bool isWeb = kIsWeb}) =>
    isWeb ? null : DriftTelemetryBuffer(driftDatabase(name: 'fcm_telemetry'));

/// The reporter over [buffer] for the install [identity] names, pointed at the
/// same API the sandbox sends through.
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
/// `TelemetryBuffer` is deliberately left unregistered when there is none, rather
/// than registered as some do-nothing stand-in: every hook already treats
/// telemetry as optional through [PushTelemetry], so silence belongs at that seam
/// and nothing else in the app asks for a buffer.
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
/// **Conditional, never eager.** A fresh clone still holds the placeholder
/// credentials, and registering a `FirebasePushSource` regardless would mean the
/// app crashes at startup instead of opening and explaining what to run. The
/// reason travels back as the return value because it belongs in the banner the
/// repository publishes.
Future<String?> _registerPushSource(
  BackgroundMessageHandler onBackgroundMessage,
  FirebaseOptions options,
) async {
  PushSource source = const DisabledPushSource();
  String? setupError;
  try {
    source = await _startPushSource(onBackgroundMessage, options);
  } catch (error) {
    // Firebase failing to start must not stop the app from opening — the
    // reason is shown in the UI instead.
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

/// Starts local notifications, degrading to silence rather than failing.
///
/// A broken notification plugin should cost the banners, not the app — the same
/// principle `DisabledPushSource` applies when Firebase will not start.
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

/// The sender for a working setup, or one that explains why it cannot send.
NotificationSender _senderFor(String? setupError) => setupError == null
    ? HttpNotificationSender(
        client: http.Client(),
        baseUrl: Uri.parse(defaultApiBaseUrl),
      )
    : UnavailableNotificationSender(setupError);
