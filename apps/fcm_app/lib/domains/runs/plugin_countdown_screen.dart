import 'package:app_settings/app_settings.dart';
import 'package:fcm_app/domains/runs/countdown_screen.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The real [CountdownScreen].
///
/// Every call is swallowed on failure. A handset that refuses to stay awake, or
/// refuses a brightness change, should cost the convenience, not the countdown —
/// the send is already scheduled on the server by the time this screen exists.
class PluginCountdownScreen implements CountdownScreen {
  const PluginCountdownScreen();

  @override
  Future<void> keepAwake() => _quietly(() => WakelockPlus.enable());

  // Each of these two steps is guarded on its own, rather than the pair sharing one
  // `_quietly`: a failing keep-awake call must not suppress the brightness call next
  // to it, or `release` would leave the display pinned at minimum brightness after
  // the user has already left the countdown screen — the one failure this class
  // cannot let pass as a mere lost convenience.
  @override
  Future<void> dim() async {
    await _quietly(
      () => ScreenBrightness.instance.setApplicationScreenBrightness(0),
    );
    await _quietly(WakelockPlus.disable);
  }

  @override
  Future<void> release() async {
    await _quietly(WakelockPlus.disable);
    await _quietly(ScreenBrightness.instance.resetApplicationScreenBrightness);
  }

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
