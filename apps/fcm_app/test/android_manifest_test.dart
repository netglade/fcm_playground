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
///
/// Comments are stripped and the assertions are patterns rather than
/// [String.contains], so that a line commented out, or a value that drifts away
/// from the name it belongs to, fails rather than passes. Stripping is what
/// makes both assertions real: commenting a declaration out leaves its text in
/// the file, so a match over the raw manifest still finds it.
void main() {
  late String manifest;

  setUpAll(() {
    manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  });

  test('declares USE_FULL_SCREEN_INTENT', () {
    expect(
      manifest,
      matches(
        RegExp(
          r'<uses-permission\s+android:name='
          r'"android\.permission\.USE_FULL_SCREEN_INTENT"',
        ),
      ),
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
      matches(
        RegExp(
          r'android:name='
          r'"com\.google\.firebase\.messaging\.default_notification_channel_id"'
          r'\s+android:value="'
          '$notificationChannelId"',
        ),
      ),
      reason:
          'FCM draws its own tray entries while the app is backgrounded. '
          'Without this id they land on its fallback channel at default '
          'importance, so they arrive without popping as heads-up — where the '
          'same push does pop in the foreground, which the app draws itself',
    );
  });
}
