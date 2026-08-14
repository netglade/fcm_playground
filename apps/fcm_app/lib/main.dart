import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import 'di/service_locator.dart';
import 'firebase_options.dart';
import 'notifications/notification_presenter.dart';
import 'push/inbox_cubit.dart';
import 'push/push_repository.dart';
import 'push/push_source.dart';
import 'push/remote_message_payload.dart';
import 'push/shared_preferences_push_payload_store.dart';
import 'sandbox/notification_sender.dart';
import 'sandbox/sandbox_cubit.dart';
import 'telemetry/push_telemetry.dart';
import 'telemetry/report_push_event.dart';
import 'telemetry/shared_preferences_device_identity.dart';
import 'ui/fcm_sample_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every GladeModel built below — the whole payload form — depends on this
  // having run, and it has to run exactly once, before the first one exists.
  GladeForms.initialize();

  // Construction lives in the locator; what is left here is the startup
  // sequence, which is not construction: the order these run in is a fact about
  // launching the app, not about how any one collaborator is built.
  await configureDependencies(onBackgroundMessage: _onBackgroundMessage);

  final telemetry = getIt<PushTelemetry>();
  final repository = getIt<PushRepository>()..listen();
  await repository.restore();
  await repository.refreshToken();
  // Sends what the background isolate buffered while the app was not running:
  // those arrivals deliberately did not flush themselves, so without this they
  // would wait for the next foreground event to carry them. Not awaited — the
  // first frame does not wait for a network round trip — and quiet, because a
  // flush that cannot reach its own database must not cost the launch.
  unawaited(_flushQuietly(telemetry));

  // Both channels mean the same thing to the repository: FCM reports taps on the
  // tray entries it drew itself, and the presenter reports taps on the banners the
  // app posted while it was in the foreground.
  getIt<PushSource>().taps.listen(repository.requestOpen);
  getIt<NotificationPresenter>().taps.listen(repository.requestOpen);

  final sandbox = SandboxCubit(
    sender: getIt<NotificationSender>(),
    token: () => repository.token,
    telemetry: telemetry,
  );

  runApp(FcmSampleApp(inbox: InboxCubit(repository), sandbox: sandbox));
}

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
/// picks the payload up in `PushRepository.restore` at next launch, or in
/// `drainPending` when the app resumes.
///
/// Only ever runs for a payload carrying `data`: a notification-only push is
/// drawn by the system and never wakes this handler, so the absence of a
/// `received_bg` for one of those is correct rather than a missed event.
///
/// **Everything here is built by hand, deliberately.** This runs in its own
/// isolate, with its own memory, so `configureDependencies` has not run and
/// nothing is registered — a `getIt` lookup would throw and background telemetry
/// would silently stop recording. Configuring a locator here instead would build
/// a presenter, a sender and a repository this handler must never use, and start
/// Firebase Messaging's listeners in an isolate that is about to be killed. So it
/// calls the two constructions it actually needs directly, which are the same two
/// the locator calls — one definition of the database name, which is what keeps a
/// `received_bg` flushable from the foreground.
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
  final buffer = openTelemetryBuffer();
  if (buffer == null) {
    return;
  }
  try {
    await reportWithoutFlushing(
      telemetryReporterOn(buffer, SharedPreferencesDeviceIdentity()),
      TelemetryEventType.receivedBg,
      payload,
    );
  } finally {
    await buffer.close();
  }
}
