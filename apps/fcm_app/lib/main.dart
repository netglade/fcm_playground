import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'firebase_setup.dart';
import 'push/disabled_push_source.dart';
import 'push/firebase_push_source.dart';
import 'push/push_inbox.dart';
import 'push/push_source.dart';
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

  final inbox = PushInbox(source, setupError: setupError)..listen();
  await inbox.refreshToken();

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

/// Handles pushes that arrive while the app is backgrounded or terminated.
///
/// Must be a top-level function, and annotated so AOT compilation keeps it
/// reachable from the background isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // A production app would persist the payload here. The sample only needs to
  // demonstrate that the entry point is registered.
  debugPrint('Background push: ${message.messageId}');
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
