import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:fcm_app/app.dart';
import 'package:fcm_app/di/service_locator.dart';
import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/domains/settings/settings.dart';
import 'package:fcm_app/domains/telemetry/telemetry.dart';
import 'package:fcm_app/firebase_options.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every GladeModel below needs this, exactly once, before the first exists.
  GladeForms.initialize();

  // Ahead of configureDependencies, not merely ahead of the first frame:
  // channel names freeze when Android first creates them, and
  // configureDependencies is what registers the channels. Leave the locale at
  // slang's English default until then and a fresh install keeps English
  // channel names forever. Reads the store directly, so it needs no getIt.
  //
  // The block at the end of this function still has to run — it also subscribes
  // to device locale changes, which this one-shot restore does not.
  await restoreStoredLocale();

  await configureDependencies(onBackgroundMessage: _onBackgroundMessage);

  final telemetry = getIt<PushTelemetry>();
  final repository = getIt<PushRepository>()..listen();
  await repository.restore();
  await repository.refreshToken();
  // Sends what the background isolate buffered: those arrivals deliberately did
  // not flush themselves. Unawaited — the first frame waits for no network.
  unawaited(_flushQuietly(telemetry));

  // Two routes, one meaning: FCM reports taps on tray entries it drew, the
  // presenter on banners the app drew. Each labels its own, which is how the
  // repository knows which state an `opened` came from.
  getIt<PushSource>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  // Only the presenter has dismissals — FCM's tray entries never went through
  // the plugin, so a swipe on one reports nothing.
  getIt<NotificationPresenter>().dismissals.listen(repository.reportDismissed);

  // Before the first frame, so the app never flashes English on the way to the
  // stored language. `useDeviceLocaleSync` is "follow the system": closest
  // supported locale, and it keeps listening for device changes.
  final storedLocale = await getIt<LocaleStore>().read();
  if (storedLocale == null) {
    LocaleSettings.useDeviceLocaleSync();
  } else {
    LocaleSettings.setLocaleSync(storedLocale);
  }

  runApp(TranslationProvider(child: const App()));
}

Future<void> _flushQuietly(PushTelemetry telemetry) async {
  try {
    await telemetry.flush();
  } on Object catch (error) {
    debugPrint('Buffered telemetry could not be sent: $error');
  }
}

/// Handles pushes arriving while the app is backgrounded or terminated.
///
/// Top-level and annotated, so AOT keeps it reachable. It persists, records,
/// and draws data-only payloads itself — which is the only way an action button
/// can exist, since an FCM-drawn tray entry cannot carry one. Runs only for a
/// payload carrying `data`.
///
/// Everything is built by hand: `configureDependencies` has not run here, so
/// `getIt` would throw. Running it instead would build collaborators this
/// handler must never use and start listeners in a dying isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Own memory, own plugin registry — both need setting up before
  // shared_preferences is reachable.
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final payload = remoteMessageToPayload(message);
  await SharedPreferencesPushPayloadStore().appendPending(payload);

  var drawn = false;
  if (shouldDrawInBackground(message)) {
    try {
      await drawBackgroundNotification(
        const PushMessageParser().parse(payload),
      );
      drawn = true;
    } on Object catch (error) {
      // A bad payload or failing plugin costs the notification, not the record
      // of the arrival written below.
      debugPrint('No background notification for ${message.messageId}: $error');
    }
  }

  // Recorded, deliberately not flushed: this isolate can die mid-request and
  // lose the event. Closed either way, so twenty wakes do not leave twenty
  // open connections.
  final buffer = openTelemetryBuffer();
  if (buffer == null) {
    return;
  }
  final reporter = telemetryReporterOn(
    buffer,
    SharedPreferencesDeviceIdentity(),
  );
  try {
    await reportWithoutFlushing(
      reporter,
      TelemetryEventType.receivedBg,
      payload,
    );
    if (drawn) {
      await reportWithoutFlushing(
        reporter,
        TelemetryEventType.displayed,
        payload,
      );
    }
  } finally {
    await buffer.close();
  }
}
