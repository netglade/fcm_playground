import 'dart:io';

import 'package:fcm_app/domains/notifications/entities/notification_content.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two manifest facts the app's Dart code depends on and cannot observe.
///
/// Neither is reachable from a widget test: the manifest is read by Android at
/// install time, so deleting either line leaves every other test in this suite
/// green while the app quietly changes behaviour on a device. Both failures are
/// also invisible by eye — a notification still arrives, it just arrives wrong —
/// which is what makes them worth a test that reads the file as text.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
  });

  test('declares USE_FULL_SCREEN_INTENT', () {
    expect(
      manifest,
      contains('android.permission.USE_FULL_SCREEN_INTENT'),
      reason:
          'Undeclared, Android never considers the full-screen request at all, '
          'so f8_full_screen_intent degrades to a heads-up for the wrong '
          'reason and looks identical whether or not it would have been '
          'granted — which is the one thing that scenario exists to show',
    );
  });

  test('points FCM at the channel the app creates', () {
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_channel_id'),
    );
    expect(
      manifest,
      contains('android:value="$notificationChannelId"'),
      reason:
          'FCM draws its own tray entries while the app is backgrounded, and '
          'without this id they land on a default low-importance channel — '
          'silent, where the same push is heads-up in the foreground',
    );
  });
}
