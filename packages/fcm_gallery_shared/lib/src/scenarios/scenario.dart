import 'package:fcm_gallery_shared/src/scenarios/scenario_need.dart';
import 'package:fcm_gallery_shared/src/send_target.dart';

/// A payload template the Sandbox can send as-is, to demonstrate one facet of FCM's
/// `Message` model.
class Scenario {
  const Scenario({
    required this.id,
    required this.l10nKey,
    required this.group,
    required this.payloadTemplate,
    this.requiresKilledApp = false,
    this.defaultDelaySeconds = 0,
    this.needs = const [],
    this.target,
  });

  /// Stable slug, used as a widget key and in tests.
  final String id;

  /// The key its prose is filed under in the app's `strings.i18n.csv`.
  ///
  /// Equal to [id] today, and still its own field, because [id] is a *protocol*
  /// value: it rides in `data.scenario_id`, telemetry joins on it, the server
  /// reads it. Renaming it for a wire reason would silently repoint this
  /// scenario's prose at a key the CSV lacks, surfacing as a missing translation
  /// rather than the wire change it was.
  final String l10nKey;

  /// The single letter its source table is filed under — `'A'` through `'K'`.
  ///
  /// Stays a bare letter so grouping and ordering do not depend on the
  /// translations; the display name comes from
  /// `ScenarioText.scenarioGroupName`.
  final String group;

  /// An FCM v1 message, without a delivery target — the server sets that.
  ///
  /// A raw map, not an [FcmMessage]: this is the authoring format, so a template
  /// can be pasted straight from Google's REST reference.
  final Map<String, dynamic> payloadTemplate;

  /// Whether the scenario is meaningless unless the app was killed first.
  ///
  /// Shown on the card, and the hint to schedule rather than send.
  final bool requiresKilledApp;

  /// The delay the schedule sheet opens on. Zero means "no opinion".
  final int defaultDelaySeconds;

  /// Empty when the scenario works today.
  final List<ScenarioNeed> needs;

  /// Who to deliver to, or null for this device — what all but four want.
  final SendTarget? target;

  bool get isSupported => needs.isEmpty;
}
