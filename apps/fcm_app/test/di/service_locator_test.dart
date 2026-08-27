import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/push/disabled_push_source.dart';
import 'package:fcm_app/domains/push/push_source.dart';
import 'package:fcm_app/domains/push/push_repository.dart';
import 'package:fcm_app/domains/runs/shared_preferences_active_run_store.dart';
import 'package:fcm_app/domains/runs/unavailable_run_scheduler.dart';
import 'package:fcm_app/domains/runs/active_run_store.dart';
import 'package:fcm_app/domains/runs/run_scheduler.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/sandbox/unavailable_notification_sender.dart';
import 'package:fcm_app/domains/sandbox/notification_sender.dart';
import 'package:fcm_app/domains/telemetry/http_telemetry_reader.dart';
import 'package:fcm_app/domains/telemetry/silent_push_telemetry.dart';
import 'package:fcm_app/domains/telemetry/push_telemetry.dart';
import 'package:fcm_app/domains/telemetry/telemetry_buffer.dart';
import 'package:fcm_app/domains/telemetry/telemetry_reader.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Stands in for `main.dart`'s background handler, and never invoked: every test
/// here configures with placeholder credentials.
Future<void> _handler(RemoteMessage _) => Future<void>.value();

/// What `firebase_options.dart` looks like before anyone runs `flutterfire
/// configure`.
///
/// Passed in rather than read from the generated file, so this depends only on the
/// sentinel `apiKey` that `_startPushSource` checks.
/// `firebase_options_test.dart` is what checks the generated file still carries
/// it.
const _unconfigured = FirebaseOptions(
  apiKey: unconfiguredApiKey,
  appId: '1:000000000000:android:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: firebaseProjectId,
);

void main() {
  // The store and device identity read platform storage on construction, which
  // no test has.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // A global locator, so without this the second `configureDependencies` throws
  // on re-registration.
  tearDown(() => getIt.reset());

  // `isWeb: true` everywhere, because the device branch opens a file through
  // `path_provider`, which `flutter test` lacks. It is also the half that
  // matters: a Drift buffer registered on web kills the app at startup.
  Future<void> configure() => configureDependencies(
    onBackgroundMessage: _handler,
    options: _unconfigured,
    isWeb: true,
  );

  test('an unconfigured checkout is explained rather than fatal', () async {
    await configure();

    // Pinned to the instructions themselves: any *other* setup error would mean
    // the check was skipped and Firebase started with a placeholder key.
    expect(getIt<PushSource>(), isA<DisabledPushSource>());
    // `Bad state:` included — the banner shows whatever `'$error'` produced.
    expect(
      getIt<PushRepository>().setupError,
      'Bad state: $firebaseSetupInstructions',
    );
    expect(getIt<NotificationSender>(), isA<UnavailableNotificationSender>());
    expect(getIt<RunScheduler>(), isA<UnavailableRunScheduler>());
    // Reading telemetry needs no Firebase, so it stays live on an unconfigured
    // checkout.
    expect(getIt<TelemetryReader>(), isA<HttpTelemetryReader>());
    expect(getIt<ActiveRunStore>(), isA<SharedPreferencesActiveRunStore>());
    expect(getIt<StartRun>(), isA<StartRun>());
  });

  test('the repository is one instance, whoever asks', () async {
    await configure();

    // A second instance would subscribe twice to a single-subscription stream,
    // which throws, and hold its own token and messages.
    expect(getIt<PushRepository>(), same(getIt<PushRepository>()));
    // The same collaborators the app gets, or a `sent` and its arrival land in
    // different databases.
    expect(getIt<PushSource>(), same(getIt<PushSource>()));
    expect(getIt<PushTelemetry>(), same(getIt<PushTelemetry>()));
    // StartRun wraps the same scheduler everything else reads, not a second one.
    expect(getIt<StartRun>().scheduler, same(getIt<RunScheduler>()));
  });

  test('web gets silence instead of a drift buffer', () async {
    await configure();

    // `drift_flutter` throws synchronously without a `web:` argument, so a buffer
    // registered here compiles and then kills the app at startup. The only place
    // that is observable.
    expect(getIt.isRegistered<TelemetryBuffer>(), isFalse);
    expect(getIt<PushTelemetry>(), isA<SilentPushTelemetry>());
  });
}
