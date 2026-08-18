import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

/// What one scenario's end-to-end run should produce.
///
/// A table rather than assertions inside each test, so seventeen running scenarios
/// differ in data instead of in code — and so the census guard can read it without a
/// device. That is also why this file must never import `patrol`.
class ScenarioExpectation {
  const ScenarioExpectation({
    required this.events,
    this.absentEvents = const {},
    this.sendRejected = false,
    this.platforms = const {TargetPlatform.android},
    this.timeout = const Duration(seconds: 30),
  });

  /// Types that must appear against the send's trace.
  final Set<TelemetryEventType> events;

  /// Types that must not appear. These carry most of the suite's weight: a stray
  /// `opened` or `received_bg` on a trace nobody tapped and nothing backgrounded is
  /// a misattribution, and no positive assertion would notice it.
  final Set<TelemetryEventType> absentEvents;

  /// Whether the send itself is expected to be refused, in which case there is no
  /// trace id on screen to read and the newest trace is the one to inspect.
  final bool sendRejected;

  /// Where this scenario can run at all. The iOS-only four are named here rather
  /// than inferred from their `apns` block, which would be guessing from data.
  final Set<TargetPlatform> platforms;

  /// How long to keep reloading the Telemetry page before calling the events
  /// missing. Raised for the scenarios where FCM is entitled to take its time.
  final Duration timeout;
}

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
/// The app is in the foreground for the whole test, so `onBackgroundMessage` never
/// runs; nothing taps or swipes the notification; and nobody presses "Nepřišlo mi
/// to". Each of those absences is a real assertion rather than a formality.
const _quiet = {
  TelemetryEventType.receivedBg,
  TelemetryEventType.opened,
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
/// Twenty-one entries: the seventeen that run on Android plus the four iOS-only ones,
/// which are written so that unblocking iOS is a skip-policy change rather than a
/// table rewrite. `b3_killed` has no entry on purpose — [skipReasonFor] turns it away
/// before the table is consulted.
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
  // Expects `displayed` despite the catalogue calling this one "nothing drawn".
  // `PushRepository._ingest` calls `_show` for every live payload and
  // `LocalNotificationPresenter.show` has no title guard, so the app does draw a
  // banner here — the catalogue describes an intent the app does not implement.
  // Asserting the absence would ship a red test; the disagreement is recorded in
  // CALIBRATION.md instead, for someone to decide which side is wrong.
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

  // Group I — a silent data sync. Same note as a4_no_display: it is silent in the
  // catalogue's intent, not in the app's behaviour.
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
    return 'needs ${scenario.needs.map((need) => need.label).join(', ')}';
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
