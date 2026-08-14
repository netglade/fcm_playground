import '../send_target.dart';
import 'scenario_need.dart';

/// A payload template the Sandbox can send as-is, to demonstrate one facet
/// of FCM's `Message` model.
///
/// A `Scenario` template stays a raw map all the way to send time: it is the
/// *authoring* format, so it can be pasted straight out of Google's REST
/// reference without translation, and `FcmMessage.fromJson` is what proves it
/// maps onto the typed model built in Tasks 1–7.
class Scenario {
  /// Creates a scenario. [payloadTemplate] is the sender's `message` object,
  /// without a delivery target — the server assigns that at send time.
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

  /// The heading this scenario is filed under in the Sandbox.
  final String group;

  /// Shown as the scenario's name in the Sandbox.
  final String title;

  /// What should happen, and what to watch for while it does.
  final String description;

  /// A device- or platform-specific caveat, when there is one.
  final String? expectation;

  /// An FCM v1 message, without a delivery target — the server sets that.
  ///
  /// Deliberately a raw map rather than an [FcmMessage]: this is the authoring
  /// format, so a template can be pasted straight out of Google's REST
  /// reference. `FcmMessage.fromJson` is what turns it into something editable.
  final Map<String, dynamic> payloadTemplate;

  /// Whether the scenario only demonstrates anything with the app killed.
  ///
  /// Carried but not acted on yet: Spec 2 turns this into a delayed send. The
  /// Sandbox shows it as a hint so the field is not silently meaningless.
  final bool requiresKilledApp;

  /// Seconds to hold the send for, once Spec 2 implements delaying.
  final int defaultDelaySeconds;

  /// What this scenario needs before it demonstrates anything, empty when it
  /// works today.
  final List<ScenarioNeed> needs;

  /// A step the user must perform by hand — an adb command, a settings change —
  /// when the payload alone cannot produce the scenario.
  final String? manualSteps;

  /// Who to deliver to, or null for this device, which is what all but four
  /// scenarios want.
  final SendTarget? target;

  /// Whether the app can demonstrate this scenario as it stands.
  bool get isSupported => needs.isEmpty;
}
