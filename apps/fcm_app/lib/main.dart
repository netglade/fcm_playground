import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'firebase_setup.dart';
import 'push/disabled_push_source.dart';
import 'push/firebase_push_source.dart';
import 'push/push_inbox.dart';
import 'push/push_source.dart';
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

  runApp(FcmSampleApp(inbox: inbox));
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
/// Throws [StateError] while `firebase_options.dart` still holds the placeholder
/// values that ship with this repo.
Future<PushSource> _startPushSource() async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.projectId == unconfiguredProjectId) {
    throw StateError(firebaseSetupInstructions);
  }

  await Firebase.initializeApp(options: options);
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  final source = FirebasePushSource(FirebaseMessaging.instance);
  await source.requestPermission();
  await source.start();

  return source;
}
