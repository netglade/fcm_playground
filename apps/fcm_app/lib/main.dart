import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import 'app.dart';
import 'di/service_locator.dart';
import 'domains/notifications/data_sources/background_notification_draw.dart';
import 'domains/notifications/entities/notification_presenter.dart';
import 'domains/push/data_sources/shared_preferences_push_payload_store.dart';
import 'domains/push/entities/push_source.dart';
import 'domains/push/entities/remote_message_payload.dart';
import 'domains/push/repositories/push_repository.dart';
import 'domains/settings/entities/locale_store.dart';
import 'domains/telemetry/data_sources/shared_preferences_device_identity.dart';
import 'domains/telemetry/entities/push_telemetry.dart';
import 'domains/telemetry/report_push_event.dart';
import 'firebase_options.dart';
import 'i18n/isolate_locale.dart';
import 'i18n/translations.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every GladeModel built below depends on this having run, and it has to run
  // exactly once, before the first one exists.
  GladeForms.initialize();

  // Ahead of configureDependencies, not just ahead of the first frame: a channel's
  // name and description are frozen the moment Android first creates it, and
  // configureDependencies is what builds LocalNotificationPresenter, whose
  // initialize() registers every channel. If the locale were still whatever slang
  // defaults to (the base locale, English) when that happens, a fresh install would
  // get English channel names forever, regardless of the language the user picked —
  // the block at the bottom of this function that reads the real preference would
  // already be too late. This early call does not need getIt: unlike that later
  // block, it reads the locale store directly. The later block still has to run —
  // it also subscribes to device locale changes, which this one-shot restore
  // deliberately does not.
  await restoreStoredLocale();

  await configureDependencies(onBackgroundMessage: _onBackgroundMessage);

  final telemetry = getIt<PushTelemetry>();
  final repository = getIt<PushRepository>()..listen();
  await repository.restore();
  await repository.refreshToken();
  // Sends what the background isolate buffered while the app was not running:
  // those arrivals deliberately did not flush themselves. Not awaited — the first
  // frame does not wait for a network round trip.
  unawaited(_flushQuietly(telemetry));

  // Both channels mean the same thing to the repository: FCM reports taps on the
  // tray entries it drew itself, the presenter reports taps on the banners the app
  // posted while in the foreground. Each labels its own, which is why the repository
  // can say which state an `opened` came from.
  getIt<PushSource>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  getIt<NotificationPresenter>().taps.listen(
    (tap) => repository.requestOpen(tap.id, tap.from, actionId: tap.actionId),
  );
  // Only the presenter has dismissals: FCM's own tray entries were never posted
  // through the plugin, so nothing reports when one of those is swiped away.
  getIt<NotificationPresenter>().dismissals.listen(repository.reportDismissed);

  // Applied before the first frame so the app never flashes English on its way to
  // the stored language. `useDeviceLocaleSync` is what "follow the system" means:
  // slang picks the closest supported locale and keeps listening for device changes.
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

/// Handles pushes that arrive while the app is backgrounded or terminated.
///
/// Must be a top-level function, and annotated so AOT compilation keeps it
/// reachable from the background isolate. It persists, records, and — for a
/// data-only payload, which FCM does not draw — draws the notification itself.
/// That is what lets an action button exist at all: an FCM-drawn tray entry
/// cannot carry one. Only ever runs for a payload carrying `data`; a
/// notification-only push never wakes this handler.
///
/// Everything here is built by hand: this runs in its own isolate, so
/// `configureDependencies` has not run and a `getIt` lookup would throw.
/// Configuring a locator here instead would build a presenter, a sender and a
/// repository this handler must never use, and start Firebase Messaging's
/// listeners in an isolate that is about to be killed.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // This isolate has its own memory and its own plugin registry, so both need
  // setting up before shared_preferences can be reached.
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
      // A malformed payload or a failing plugin costs the notification, not the
      // record of the arrival that is about to be written below.
      debugPrint('No background notification for ${message.messageId}: $error');
    }
  }

  // Recorded and deliberately not flushed: this isolate can be killed at any
  // moment, so a request in flight would lose the event it was carrying. Closed
  // either way, so a handset that wakes for twenty pushes does not leave twenty
  // connections to the file open.
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
