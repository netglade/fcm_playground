import 'package:drift_flutter/drift_flutter.dart';
import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/domains/sandbox/sandbox.dart';
import 'package:fcm_app/domains/settings/settings.dart';
import 'package:fcm_app/domains/telemetry/telemetry.dart';
import 'package:fcm_app/firebase_options.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

/// The app's locator, holding only what outlives a page.
///
/// Never a cubit: one here would outlive its page and carry state into the
/// next. Cubits are made by the widget that owns them; what they are built
/// *from* lives here.
final getIt = GetIt.instance;

/// Builds and registers every long-lived collaborator, once, before the first
/// frame.
///
/// [onBackgroundMessage] is passed in because it runs in its own isolate: it
/// must be top-level in `main.dart` for AOT to keep it reachable, and it cannot
/// see anything registered here.
///
/// [options] and [isWeb] are test seams.
Future<void> configureDependencies({
  required BackgroundMessageHandler onBackgroundMessage,
  FirebaseOptions? options,
  bool isWeb = kIsWeb,
}) async {
  final setupError = await _registerPushSource(
    onBackgroundMessage,
    options ?? DefaultFirebaseOptions.currentPlatform,
  );
  // Shared with the channel reader below — and unavoidably so:
  // `FlutterLocalNotificationsPlugin()` is a factory that always returns the
  // same singleton.
  final plugin = FlutterLocalNotificationsPlugin();
  final presenter = await _startPresenter(plugin);
  getIt
    ..registerSingleton<PushPayloadStore>(SharedPreferencesPushPayloadStore())
    ..registerSingleton<PressedActionStore>(
      SharedPreferencesPressedActionStore(),
    )
    ..registerSingleton<ReplyStore>(SharedPreferencesReplyStore())
    ..registerSingleton<DeviceIdentity>(SharedPreferencesDeviceIdentity())
    ..registerSingleton<ActiveRunStore>(SharedPreferencesActiveRunStore())
    ..registerSingleton<LocaleStore>(const SharedPreferencesLocaleStore())
    ..registerSingleton<NotificationPresenter>(presenter)
    ..registerSingleton<NotificationChannelReader>(
      PluginNotificationChannelReader(plugin),
    )
    ..registerSingleton<NotificationSender>(_senderFor(setupError))
    ..registerSingleton<RunScheduler>(_runSchedulerFor(setupError))
    ..registerSingleton<TelemetryReader>(
      // Unconditional, unlike the sender and scheduler: those need a
      // registration token, reading telemetry needs no Firebase at all.
      HttpTelemetryReader(
        client: http.Client(),
        baseUrl: Uri.parse(defaultApiBaseUrl),
      ),
    );
  getIt.registerSingleton<StartRun>(
    StartRun(scheduler: getIt<RunScheduler>(), active: getIt<ActiveRunStore>()),
  );
  _registerTelemetry(isWeb: isWeb);
  // Necessarily a singleton: a second instance would subscribe twice to a
  // single-subscription stream, which throws, and give the app two disagreeing
  // inboxes.
  getIt.registerSingleton<PushRepository>(
    PushRepository(
      getIt<PushSource>(),
      store: getIt<PushPayloadStore>(),
      presenter: getIt<NotificationPresenter>(),
      // The reporter the sandbox also sends through, so a `not_received` and
      // the `sent` it contradicts share one database.
      telemetry: getIt<PushTelemetry>(),
      pressedActions: getIt<PressedActionStore>(),
      replies: getIt<ReplyStore>(),
      setupError: setupError,
    ),
  );
}

/// Opens the on-device event buffer, or null where there is none.
///
/// Public because the background isolate needs the same construction and cannot
/// reach [getIt] — both sides must name the same file, or a `received_bg`
/// written to one database is flushed from another and never sent.
///
/// Null on web deliberately: `drift_flutter`'s web path throws `ArgumentError`
/// *synchronously* without a `web:` argument, so the build compiles and dies at
/// startup.
DriftTelemetryBuffer? openTelemetryBuffer({bool isWeb = kIsWeb}) =>
    isWeb ? null : DriftTelemetryBuffer(driftDatabase(name: 'fcm_telemetry'));

/// The reporter over [buffer] for the install [identity] names.
///
/// A parameter, not a lookup, so the background isolate can pass its own —
/// nothing is registered in that isolate.
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
/// `TelemetryBuffer` is left unregistered rather than stubbed: [PushTelemetry]
/// is already the seam where telemetry is optional.
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
/// Never eager: a fresh clone still holds placeholder credentials, and starting
/// Firebase regardless would crash instead of explaining what to run.
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
/// Throws [StateError] while `firebase_options.dart` holds its shipped
/// placeholders. Any field would serve as the signal; the API key is checked
/// because it is the one `Firebase.initializeApp` rejects itself, later and far
/// less legibly than [firebaseSetupInstructions].
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

/// Starts local notifications, degrading to silence: a broken plugin should
/// cost the banners, not the app.
Future<NotificationPresenter> _startPresenter(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final presenter = LocalNotificationPresenter(plugin: plugin);
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
