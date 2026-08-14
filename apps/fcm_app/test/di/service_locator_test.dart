import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:fcm_app/push/disabled_push_source.dart';
import 'package:fcm_app/push/push_repository.dart';
import 'package:fcm_app/push/push_source.dart';
import 'package:fcm_app/sandbox/notification_sender.dart';
import 'package:fcm_app/sandbox/unavailable_notification_sender.dart';
import 'package:fcm_app/telemetry/push_telemetry.dart';
import 'package:fcm_app/telemetry/silent_push_telemetry.dart';
import 'package:fcm_app/telemetry/telemetry_buffer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Stands in for `main.dart`'s background handler.
///
/// Never invoked: every test here configures with placeholder credentials, so the
/// source never gets far enough to hand it to Firebase Messaging.
Future<void> _handler(RemoteMessage _) => Future<void>.value();

/// What `firebase_options.dart` looks like in a checkout nobody has run
/// `flutterfire configure` on.
///
/// Passed in rather than read from the generated file because **this** checkout's
/// credentials are real, so the sentinel no longer fires for them — and the fresh
/// clone is the case worth guarding. The other three values are shaped like real
/// ones and are never used: the key is what the check reads.
const _unconfigured = FirebaseOptions(
  apiKey: unconfiguredApiKey,
  appId: '1:000000000000:android:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: firebaseProjectId,
);

void main() {
  // The store and the device identity read platform storage the moment they are
  // built, which no test has. The in-memory backend is the same one
  // `push_payload_store_test` uses; nothing here asserts on what it holds.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // The locator is a global, so each test hands the next one an empty one back.
  // Without this the second `configureDependencies` throws on re-registration
  // and this file's outcome would depend on the order its tests ran in.
  tearDown(() => getIt.reset());

  // `isWeb: true` everywhere, and that is a limit of the VM rather than a
  // preference: on the device branch `driftDatabase` starts opening a file
  // through `path_provider` as soon as it is built, and `flutter test` has
  // neither that plugin nor drift's bundled `sqlite3`. So the web branch is the
  // half a test can observe — which is the half that matters, since a Drift
  // buffer registered on web kills the app at startup and nothing else catches
  // it.
  Future<void> configure() => configureDependencies(
    onBackgroundMessage: _handler,
    options: _unconfigured,
    isWeb: true,
  );

  test('an unconfigured checkout is explained rather than fatal', () async {
    await configure();

    // The whole point of the sentinel: a fresh clone starts, says what to run,
    // and registers a source that cannot receive rather than one that cannot be
    // built. Pinned to the instructions themselves, because any *other* setup
    // error here would mean the check was skipped and Firebase was asked to
    // start with a placeholder key.
    expect(getIt<PushSource>(), isA<DisabledPushSource>());
    // `Bad state:` and not a trimmed message, because the banner has always shown
    // whatever `'$error'` produced and this task must not change what it says.
    expect(
      getIt<PushRepository>().setupError,
      'Bad state: $firebaseSetupInstructions',
    );
    expect(getIt<NotificationSender>(), isA<UnavailableNotificationSender>());
  });

  test('the repository is one instance, whoever asks', () async {
    await configure();

    // A second instance would subscribe a second time to a single-subscription
    // push stream — which throws — and hold its own token and its own messages.
    expect(getIt<PushRepository>(), same(getIt<PushRepository>()));
    // Every other collaborator the repository was built from is the same one the
    // rest of the app is handed, or the sandbox would record a `sent` into one
    // database while an arrival went to another.
    expect(getIt<PushSource>(), same(getIt<PushSource>()));
    expect(getIt<PushTelemetry>(), same(getIt<PushTelemetry>()));
  });

  test('web gets silence instead of a drift buffer', () async {
    await configure();

    // `drift_flutter` throws `ArgumentError` synchronously without a `web:`
    // argument, so a buffer registered here would compile on web and kill the
    // app at startup — which `flutter build web --release` cannot catch, because
    // it only compiles. This is the only place that failure is observable.
    expect(getIt.isRegistered<TelemetryBuffer>(), isFalse);
    expect(getIt<PushTelemetry>(), isA<SilentPushTelemetry>());
  });
}
