import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
import 'sandbox/sandbox_controller.dart';
import 'sandbox/unavailable_notification_sender.dart';
import 'ui/fcm_sample_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final inbox = PushInbox(
    source,
    store: store,
    presenter: presenter,
    setupError: setupError,
  )..listen();
  await inbox.restore();
  await inbox.refreshToken();

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
  final sandbox = SandboxController(sender: sender, token: () => inbox.token);

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

/// Handles pushes that arrive while the app is backgrounded or terminated.
///
/// Must be a top-level function, and annotated so AOT compilation keeps it
/// reachable from the background isolate.
///
/// It only persists. FCM has already drawn the tray entry for this message, so
/// posting a notification here would show it twice. The UI isolate picks the
/// payload up in `PushInbox.restore` at next launch, or in `drainPending` when
/// the app resumes.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // This isolate has its own memory and its own plugin registry, so both need
  // setting up before shared_preferences can be reached.
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SharedPreferencesPushPayloadStore().appendPending(
    remoteMessageToPayload(message),
  );
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
