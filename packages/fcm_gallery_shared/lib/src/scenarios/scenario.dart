import '../send_target.dart';
import 'scenario_need.dart';

/// A payload template the Sandbox can send as-is, to demonstrate one facet of FCM's
/// `Message` model.
class Scenario {
  const Scenario({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.payloadTemplate,
    this.expectation,
    this.requiresKilledApp = false,
    this.defaultDelaySeconds = 0,
    this.needs = const [],
    this.manualSteps,
    this.target,
  });

  /// Stable slug, used as a widget key and in tests.
  final String id;

  final String group;

  final String title;

  /// What should happen, and what to watch for while it does.
  final String description;

  /// A device- or platform-specific caveat, when there is one.
  final String? expectation;

  /// An FCM v1 message, without a delivery target — the server sets that.
  ///
  /// Deliberately a raw map rather than an [FcmMessage]: this is the authoring
  /// format, so a template can be pasted straight out of Google's REST reference.
  final Map<String, dynamic> payloadTemplate;

  /// Whether the scenario is meaningless unless the app has been killed first.
  ///
  /// Shown on the card and used as the hint that this is one to schedule rather
  /// than send.
  final bool requiresKilledApp;

  /// The delay the schedule sheet opens on. Zero means "no opinion", and the sheet
  /// falls back to its own default.
  final int defaultDelaySeconds;

  /// Empty when the scenario works today.
  final List<ScenarioNeed> needs;

  /// A step the user must perform by hand — an adb command, a settings change —
  /// when the payload alone cannot produce the scenario.
  final String? manualSteps;

  /// Who to deliver to, or null for this device, which is what all but four
  /// scenarios want.
  final SendTarget? target;

  bool get isSupported => needs.isEmpty;
}
