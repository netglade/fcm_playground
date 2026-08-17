import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/push/data_sources/disabled_push_source.dart';
import 'package:fcm_app/domains/push/entities/push_source.dart';
import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/domains/runs/data_sources/shared_preferences_active_run_store.dart';
import 'package:fcm_app/domains/runs/data_sources/unavailable_run_scheduler.dart';
import 'package:fcm_app/domains/runs/entities/active_run_store.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/sandbox/data_sources/unavailable_notification_sender.dart';
import 'package:fcm_app/domains/sandbox/entities/notification_sender.dart';
import 'package:fcm_app/domains/telemetry/data_sources/silent_push_telemetry.dart';
import 'package:fcm_app/domains/telemetry/entities/push_telemetry.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_buffer.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Stands in for `main.dart`'s background handler, and never invoked: every test
/// here configures with placeholder credentials.
Future<void> _handler(RemoteMessage _) => Future<void>.value();

/// What `firebase_options.dart` looks like in a checkout nobody has run
/// `flutterfire configure` on.
///
/// Passed in rather than read from the generated file, because this checkout's
/// credentials are real and the fresh clone is the case worth guarding.
const _unconfigured = FirebaseOptions(
  apiKey: unconfiguredApiKey,
  appId: '1:000000000000:android:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: firebaseProjectId,
);

void main() {
  // The store and the device identity read platform storage the moment they are
  // built, which no test has.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // The locator is a global: without this the second `configureDependencies`
  // throws on re-registration.
  tearDown(() => getIt.reset());

  // `isWeb: true` everywhere, and that is a limit of the VM: the device branch
  // opens a file through `path_provider`, which `flutter test` does not have. The
  // web branch is also the half that matters, since a Drift buffer registered
  // there kills the app at startup.
  Future<void> configure() => configureDependencies(
    onBackgroundMessage: _handler,
    options: _unconfigured,
    isWeb: true,
  );

  test('an unconfigured checkout is explained rather than fatal', () async {
    await configure();

    // The whole point of the sentinel. Pinned to the instructions themselves,
    // because any *other* setup error would mean the check was skipped and Firebase
    // was asked to start with a placeholder key.
    expect(getIt<PushSource>(), isA<DisabledPushSource>());
    // `Bad state:` and not a trimmed message: the banner shows whatever `'$error'`
    // produced.
    expect(
      getIt<PushRepository>().setupError,
      'Bad state: $firebaseSetupInstructions',
    );
    expect(getIt<NotificationSender>(), isA<UnavailableNotificationSender>());
    expect(getIt<RunScheduler>(), isA<UnavailableRunScheduler>());
    expect(getIt<ActiveRunStore>(), isA<SharedPreferencesActiveRunStore>());
  });

  test('the repository is one instance, whoever asks', () async {
    await configure();

    // A second instance would subscribe a second time to a single-subscription
    // push stream — which throws — and hold its own token and its own messages.
    expect(getIt<PushRepository>(), same(getIt<PushRepository>()));
    // The same collaborators the rest of the app is handed, or the sandbox would
    // record a `sent` into one database while an arrival went to another.
    expect(getIt<PushSource>(), same(getIt<PushSource>()));
    expect(getIt<PushTelemetry>(), same(getIt<PushTelemetry>()));
  });

  test('web gets silence instead of a drift buffer', () async {
    await configure();

    // `drift_flutter` throws `ArgumentError` synchronously without a `web:`
    // argument, so a buffer registered here would compile and then kill the app at
    // startup. This is the only place that failure is observable.
    expect(getIt.isRegistered<TelemetryBuffer>(), isFalse);
    expect(getIt<PushTelemetry>(), isA<SilentPushTelemetry>());
  });
}
