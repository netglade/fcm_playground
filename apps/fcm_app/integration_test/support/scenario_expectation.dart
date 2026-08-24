import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

/// What one scenario's end-to-end run should produce.
///
/// A table rather than assertions inside each test, so twenty running scenarios
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
