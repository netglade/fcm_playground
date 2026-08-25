import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

// Every consumer imports `support/expected_events.dart` and names
// `ScenarioExpectation` through it — that import path is the contract Tasks 4
// and 5 depend on. `ScenarioExpectation` itself lives in its own file so that
// file's name matches its one class; the export makes the split invisible to
// every consumer, and the import is what lets this file keep using the type
// below.
import 'scenario_expectation.dart';
export 'scenario_expectation.dart';

/// The platform this suite runs on.
///
/// A constant rather than `defaultTargetPlatform`: the census guard runs under
/// `flutter test` on Linux, where `defaultTargetPlatform` is `TargetPlatform.linux`
/// and every Android expectation would read as skipped. The suite is Android-only by
/// decision — the spec rules iOS setup out — so the decision is written down instead
/// of sampled from the host.
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
/// The app is in the foreground for the whole test, so `onBackgroundMessage`
/// never runs; nothing taps, presses a button on, or swipes the notification;
/// and nobody presses "Nepřišlo mi to". Each of those absences is a real
/// assertion rather than a formality.
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
/// Twenty-six entries: the twenty-two that run on Android plus the four iOS-only
/// ones, which are written so that unblocking iOS is a skip-policy change rather
/// than a table rewrite. `b3_killed` and `f5_deeplink_killed` have no entry on
/// purpose — [skipReasonFor] turns each away before the table is consulted.
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
  // Expects `displayed`: `PushRepository._ingest` calls `_show` for every live
  // payload and `LocalNotificationPresenter.show` has no title guard, so a4
  // draws a blank tray entry — icon and app name, no text — rather than
  // nothing. The catalogue's own copy used to call this "nothing drawn"; that
  // was wrong and has been corrected there, not here. Whether the app *should*
  // suppress a titleless banner is still an open question, recorded in
  // CALIBRATION.md.
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
    // NORMAL priority entitles FCM to hold the message until the next maintenance
    // window, which is this scenario's whole point. Two minutes is generous rather
    // than sufficient — see the spec's Known limitations.
    timeout: Duration(minutes: 2),
  ),
  // Shares c2's "can fail for a correct reason" property, and worse: TTL zero
  // means FCM makes exactly one delivery attempt and discards the message if it
  // does not land, so a momentarily unreachable device fails this test for a
  // correct reason too — and unlike c2, no longer timeout can rescue it, because
  // there is no later delivery window to wait for. See CALIBRATION.md.
  'c3_ttl_zero': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'c4_ttl_long': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group E — appearance. The image cases still deliver; only the render differs,
  // and the render is not something telemetry can see.
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

  // Group F — interaction. f1 draws its buttons itself, so the delivery
  // assertions are the same as any other data-only push; pressing the button
  // is a human step, which is why `action` stays in `_quiet` — see
  // CALIBRATION.md.
  'f1_actions': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f2 is data-only too, so the same delivery assertions apply. Typing the
  // reply is a human step, exactly like pressing f1's button, which is why
  // `action` (the reply is recorded as one, with detail `reply`) stays in
  // `_quiet` here as well. Patrol cannot type into the notification shade, so
  // this expectation covers delivery and drawing only — see CALIBRATION.md.
  'f2_inline_reply': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // Group F — the two deep links that run. The tap itself is a human step, so
  // `opened` stays in `_quiet`; what these assert is that the push arrives and is
  // drawn, the same as any other notification payload.
  'f3_deeplink_foreground': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  'f4_deeplink_background': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),
  // f6 is drawn through the plugin while the app is foregrounded — the only
  // state a swipe can be detected in — so the delivery assertions are the same
  // as any other notification payload. Swiping it is a human step, which is
  // why `dismissed` stays in `_quiet`; see CALIBRATION.md.
  'f6_delete_intent': ScenarioExpectation(
    events: _deliveredAndDrawn,
    absentEvents: _quiet,
  ),

  // Group I — a silent data sync. Same note as a4_no_display: the row it writes
  // is silent, but the blank tray entry the app also draws is not — the
  // catalogue's copy now says so.
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
/// Three rules, in this order. The scenarios carrying `manualSteps` need no rule of
/// their own: every one of them also names `ScenarioNeed.manualStep`, so the first
/// rule already takes them — which is right, because a test running *on* the device
/// has no adb with which to force Doze or revoke a permission.
String? skipReasonFor(Scenario scenario) {
  if (scenario.needs.isNotEmpty) {
    // `name` rather than a localized label: this is a skip reason in a test
    // report, not UI. `needs channels, styles` reads as well as the prose did,
    // and the enum name is stable where a translated label would mean building
    // translations inside the Patrol harness for no benefit.
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
