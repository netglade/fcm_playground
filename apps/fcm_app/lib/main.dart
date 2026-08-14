import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'firebase_setup.dart';
import 'notifications/local_notification_presenter.dart';
import 'notifications/notification_presenter.dart';
import 'notifications/silent_notification_presenter.dart';
import 'push/disabled_push_source.dart';
import 'push/firebase_push_source.dart';
import 'push/push_inbox.dart';
import 'push/push_payload_store.dart';
import 'push/push_source.dart';
import 'push/remote_message_payload.dart';
import 'push/shared_preferences_push_payload_store.dart';
import 'sandbox/http_notification_sender.dart';
import 'sandbox/notification_sender.dart';
import 'sandbox/sandbox_cubit.dart';
import 'sandbox/unavailable_notification_sender.dart';
import 'telemetry/drift_telemetry_buffer.dart';
import 'telemetry/push_telemetry.dart';
import 'telemetry/report_push_event.dart';
import 'telemetry/shared_preferences_device_identity.dart';
import 'telemetry/silent_push_telemetry.dart';
import 'telemetry/telemetry_buffer.dart';
import 'telemetry/telemetry_reporter.dart';
import 'ui/fcm_sample_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every GladeModel built below — the whole payload form — depends on this
  // having run, and it has to run exactly once, before the first one exists.
  GladeForms.initialize();

  PushSource source = const DisabledPushSource();
  String? setupError;
  try {
    source = await _startPushSource();
  } catch (error) {
    // Firebase failing to start must not stop the app from opening — the
    // reason is shown in the UI instead.
    setupError = '$error';
  }

  final PushPayloadStore store = SharedPreferencesPushPayloadStore();
  final presenter = await _startPresenter();
  final buffer = _openTelemetryBuffer();
  // Silence rather than a reporter when there is no buffer to hold anything —
  // every hook already treats telemetry as optional.
  final PushTelemetry telemetry = buffer == null
      ? const SilentPushTelemetry()
      : _reporterOn(buffer);
  final inbox = PushInbox(
    source,
    store: store,
    presenter: presenter,
    telemetry: telemetry,
    setupError: setupError,
  )..listen();
  await inbox.restore();
  await inbox.refreshToken();
  // Sends what the background isolate buffered while the app was not running:
  // those arrivals deliberately did not flush themselves, so without this they
  // would wait for the next foreground event to carry them. Not awaited — the
  // first frame does not wait for a network round trip — and quiet, because a
  // flush that cannot reach its own database must not cost the launch.
  unawaited(_flushQuietly(telemetry));

  // Both channels mean the same thing to the inbox: FCM reports taps on the tray
  // entries it drew itself, and the presenter reports taps on the banners the app
  // posted while it was in the foreground.
  source.taps.listen(inbox.requestOpen);
  presenter.taps.listen(inbox.requestOpen);

  // Sending needs the same registration token the inbox listens with, so
  // there is no separate "is sending available" question to answer here.
  final NotificationSender sender = setupError == null
      ? HttpNotificationSender(
          client: http.Client(),
          baseUrl: Uri.parse(defaultApiBaseUrl),
        )
      : UnavailableNotificationSender(setupError);
  // The same reporter the inbox records arrivals through, so a `not_received`
  // and the `sent` it contradicts land in one buffer and one database.
  final sandbox = SandboxCubit(
    sender: sender,
    token: () => inbox.token,
    telemetry: telemetry,
  );

  runApp(FcmSampleApp(inbox: inbox, sandbox: sandbox));
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

/// Opens the on-device event buffer, or null where there is none.
///
/// One function rather than two constructions, because the foreground and the
/// background isolate have to name the same file: a `received_bg` written to one
/// database and flushed from another would never be sent.
///
/// **Null on web, and this is not a shortcut.** `drift_flutter`'s web path
/// requires a `web:` argument naming a `sqlite3.wasm` and a drift worker, and
/// throws `ArgumentError` *synchronously* without one — so the web build compiles
/// and then dies at startup, which `flutter build web --release` cannot catch
/// because it only compiles. Rather than ship those assets: this app cannot
/// receive a push on web at all without a VAPID key, so there is nothing on web
/// for a telemetry buffer to hold.
DriftTelemetryBuffer? _openTelemetryBuffer() =>
    kIsWeb ? null : DriftTelemetryBuffer(driftDatabase(name: 'fcm_telemetry'));

/// The reporter over [buffer], pointed at the same API the sandbox sends through.
TelemetryReporter _reporterOn(TelemetryBuffer buffer) => TelemetryReporter(
  buffer: buffer,
  identity: SharedPreferencesDeviceIdentity(),
  baseUrl: Uri.parse(defaultApiBaseUrl),
);

/// Sends the buffer without letting a failure reach the caller.
Future<void> _flushQuietly(PushTelemetry telemetry) async {
  try {
    await telemetry.flush();
  } on Object catch (error) {
    debugPrint('Buffered telemetry could not be sent: $error');
  }
}

/// Handles pushes that arrive while the app is backgrounded or terminated.
///
/// Must be a top-level function, and annotated so AOT compilation keeps it
/// reachable from the background isolate.
///
/// It persists and records. FCM has already drawn the tray entry for this
/// message, so posting a notification here would show it twice. The UI isolate
/// picks the payload up in `PushInbox.restore` at next launch, or in
/// `drainPending` when the app resumes.
///
/// Only ever runs for a payload carrying `data`: a notification-only push is
/// drawn by the system and never wakes this handler, so the absence of a
/// `received_bg` for one of those is correct rather than a missed event.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // This isolate has its own memory and its own plugin registry, so both need
  // setting up before shared_preferences can be reached.
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final payload = remoteMessageToPayload(message);
  await SharedPreferencesPushPayloadStore().appendPending(payload);

  // Recorded and deliberately not flushed. This isolate is killed once the
  // handler returns, and can be killed before that, so a request in flight would
  // lose the event it was carrying — while a buffered row is picked up by the
  // next foreground flush. Closed again either way, so a handset that wakes for
  // twenty pushes does not leave twenty connections to the file open.
  final buffer = _openTelemetryBuffer();
  if (buffer == null) {
    return;
  }
  try {
    await reportWithoutFlushing(
      _reporterOn(buffer),
      TelemetryEventType.receivedBg,
      payload,
    );
  } finally {
    await buffer.close();
  }
}

/// Starts Firebase and returns a live [PushSource].
///
/// Throws [StateError] while `firebase_options.dart` still holds placeholder
/// credentials. The project id is real, so the API key is what gets checked —
/// initialising with a fake key fails later with a far less useful message.
Future<PushSource> _startPushSource() async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.apiKey == unconfiguredApiKey) {
    throw StateError(firebaseSetupInstructions);
  }

  await Firebase.initializeApp(options: options);
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  final source = FirebasePushSource(FirebaseMessaging.instance);
  await source.requestPermission();
  await source.start();

  return source;
}
