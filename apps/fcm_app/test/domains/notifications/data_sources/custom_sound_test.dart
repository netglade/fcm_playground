import 'dart:io';

import 'package:fcm_app/domains/notifications/data_sources/notification_channels.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the custom sound', () {
    test('names a raw resource that is actually in the tree', () {
      final sound = channelById('custom_sound')!.sound;

      expect(sound, isA<RawResourceAndroidNotificationSound>());
      final name = (sound! as RawResourceAndroidNotificationSound).sound;

      // A missing raw resource does not fail the build: Android falls back to
      // the default sound at draw time, so d5 would quietly demonstrate nothing.
      // `flutter test` runs from the package root.
      expect(
        File('android/app/src/main/res/raw/$name.wav').existsSync(),
        isTrue,
        reason: 'res/raw/$name.wav is missing, so custom_sound is silent',
      );
    });
  });
}
