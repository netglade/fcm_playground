import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../entities/countdown_screen.dart';

/// The real [CountdownScreen].
///
/// Every call is swallowed on failure. A handset that refuses a wakelock or a
/// brightness change should cost the convenience, not the countdown — the send is
/// already scheduled on the server by the time this screen exists.
class PluginCountdownScreen implements CountdownScreen {
  const PluginCountdownScreen();

  @override
  Future<void> keepAwake() => _quietly(() => WakelockPlus.enable());

  @override
  Future<void> dim() => _quietly(() async {
    await ScreenBrightness.instance.setApplicationScreenBrightness(0);
    await WakelockPlus.disable();
  });

  @override
  Future<void> release() => _quietly(() async {
    await WakelockPlus.disable();
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
  });

  @override
  Future<void> openBatterySettings() => _quietly(
    () =>
        AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization),
  );
}

Future<void> _quietly(Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (error) {
    debugPrint('countdown: the screen would not cooperate: $error');
  }
}
