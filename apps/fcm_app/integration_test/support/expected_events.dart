import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

// `ScenarioExpectation` lives in its own file so the file name matches its one
// class; the export keeps that split invisible to consumers, which all import
// this path.
import 'scenario_expectation.dart';
export 'scenario_expectation.dart';

/// The platform this suite runs on.
///
/// A constant, not `defaultTargetPlatform`: the census guard runs under `flutter
/// test` on Linux, where that reads `linux` and every Android expectation would
/// look skipped. Android-only is a decision, so it is written down rather than
/// sampled from the host.
const suitePlatform = TargetPlatform.android;

/// Recorded by the API for every send, before anything reaches a device.
const _sendSide = {TelemetryEventType.queued, TelemetryEventType.sent};

/// A foreground arrival that the app then draws a banner for.
const _deliveredAndDrawn = {
  ..._sendSide,
  TelemetryEventType.receivedFg,
  TelemetryEventType.displayed,
};

/// What must stay silent on a delivered trace.
///
/// The app stays foregrounded, so `onBackgroundMessage` never runs, and nothing
/// taps, presses, swipes or reports a miss. Each absence is a real assertion.
const _quiet = {
  TelemetryEventType.receivedBg,
  TelemetryEventType.opened,
  TelemetryEventType.action,
  TelemetryEventType.dismissed,
  TelemetryEventType.notReceived,
};

/// What must stay silent when the send was refused: everything a device records.
const _nothingReachedADevice = {
  TelemetryEventType.receivedFg,
  TelemetryEventType.displayed,
  ..._quiet,
};

/// The send-side pair for a refused send.
const _sendRefused = {TelemetryEventType.queued, TelemetryEventType.sendFailed};

/// Per-scenario expectations, keyed by [Scenario.id].
///
/// Forty entries: the thirty-six that run on Android plus four iOS-only ones,
/// written so unblocking iOS is a skip-policy change rather than a table rewrite.
/// `b3_killed` and `f5_deeplink_killed` have no entry — [skipReasonFor] turns
/// them away first.
///
/// Most entries are the same delivered-and-drawn pair, because telemetry cannot
/// see a channel, a render, a category or a group summary — those are read off
/// the device by a human. Anything needing a tap, a button press, a typed reply
/// or a swipe keeps that event in [_quiet] for the same reason: Patrol does not
/// perform it.
///
/// **Derived from reading the code, not from watching a device.** See
/// `integration_test/CALIBRATION.md` for how to settle it.
const Map<String, ScenarioExpectation> scenarioExpectations = {
  // Group A — the four shapes a message can take.
  'a1_notification_only': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'a2_data_only': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'a3_hybrid': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // Expects `displayed`: `_show` runs for every live payload and `show` has no
  // title guard, so a4 draws a *blank* tray entry rather than nothing. Whether
  // it should suppress one is open — see CALIBRATION.md.
  'a4_no_display': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group B — b1 is the only state reachable without killing or backgrounding.
  'b1_foreground': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group C — priority and the delivery window.
  'c1_priority_high': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'c2_priority_normal': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
    // NORMAL priority lets FCM hold the message until the next maintenance
    // window, which is the point. Two minutes is generous, not sufficient.
    timeout: Duration(minutes: 2),
  ),
  // Can fail for a correct reason, like c2, and worse: TTL zero means one
  // delivery attempt and then discard, so a briefly unreachable device fails
  // this — and no longer timeout can rescue it. See CALIBRATION.md.
  'c3_ttl_zero': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'c4_ttl_long': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group D — the channels. All deliver and draw; the channel they draw through
  // is read off the Channels page by a human.
  'd1_importance_high': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd2_importance_default': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // d3, d4 and i1 pop no banner at all, and still record `displayed`: `_show`
  // reports once `plugin.show()` returns, not according to what was seen.
  'd3_importance_low': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd4_importance_min': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd5_custom_sound': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd6_vibration_pattern': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd7_channel_immutability': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'd8_channel_group': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group E — appearance. Only the render differs, which telemetry cannot see.
  'e2_image_remote': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'e4_image_huge': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'e5_image_404': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'e10_color_and_icon': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'e11_emoji_rtl': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group F — interaction. f1 draws its own buttons, so delivery matches any
  // data-only push.
  'f1_actions': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f2 is data-only too. Patrol cannot type into the shade, so this covers
  // delivery and drawing only.
  'f2_inline_reply': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // Group F — the two deep links that run. Delivery and drawing only.
  'f3_deeplink_foreground': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'f4_deeplink_background': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f6 is drawn through the plugin while foregrounded, the only state a swipe
  // is detectable in. Delivery assertions are unchanged.
  'f6_delete_intent': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f7's ongoing flag affects only whether a swipe dismisses it, which a human
  // watches in the tray. Same pair as every other entry.
  'f7_ongoing': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f8's refusal is a tray observation — a degraded full-screen intent looks
  // like an ordinary delivered-and-drawn push from here.
  'f8_full_screen_intent': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group G — g1's rising summary and g2's replace-in-place are both tray
  // observations, so nothing extra is asserted.
  'g1_group_summary': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'g2_update_same_id': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group H — h2's alarm category is invisible to telemetry, same as Group D.
  'h2_category_alarm': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group I — silent data sync. As with a4, the row is silent but the blank tray
  // entry the app draws is not.
  'i1_silent_no_sound': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'i2_silent_data_sync': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // The iOS-only four: written, never run on Android.
  'g4_badge_ios': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
    platforms: {TargetPlatform.iOS},
  ),
  'h3_ios_time_sensitive': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
    platforms: {TargetPlatform.iOS},
  ),
  'h5_ios_passive': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
    platforms: {TargetPlatform.iOS},
  ),
  'i3_ios_content_available': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
    platforms: {TargetPlatform.iOS},
  ),

  // Group K — the two whose success is a refusal.
  'k1_payload_oversize': ScenarioExpectation(
    events: _sendRefused,
    absentEvents: _nothingReachedADevice,
    sendRejected: true,
  ),
  'k2_invalid_token': ScenarioExpectation(
    events: _sendRefused,
    absentEvents: _nothingReachedADevice,
    sendRejected: true,
  ),
};

/// Why [scenario] cannot run here, or null when it can.
///
/// Three rules, in order. Scenarios with `manualSteps` need no rule of their own —
/// each also names `ScenarioNeed.manualStep`, and a test running *on* the device
/// has no adb to force Doze or revoke a permission.
String? skipReasonFor(Scenario scenario) {
  if (scenario.needs.isNotEmpty) {
    // `name`, not a localized label: this is a test report, not UI, and a
    // translated label would mean building translations inside the harness.
    return 'needs ${scenario.needs.map((need) => need.name).join(', ')}';
  }

  final expectation = scenarioExpectations[scenario.id];
  if (expectation != null && !expectation.platforms.contains(suitePlatform)) {
    return 'runs on ${expectation.platforms.map(_platformName).join(' / ')} only, '
        'and an iOS simulator cannot receive an FCM push at all';
  }

  if (scenario.requiresKilledApp) {
    return 'the app must be killed mid-test, which would end the Patrol test with it';
  }

  return null;
}

String _platformName(TargetPlatform platform) => switch (platform) {
  TargetPlatform.iOS => 'iOS',
  TargetPlatform.android => 'Android',
  _ => platform.name,
};
