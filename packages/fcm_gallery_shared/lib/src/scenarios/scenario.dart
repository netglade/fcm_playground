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
  /// Equal to [id] for every scenario today, and still its own field: [id] is a
  /// *protocol* value. It rides in `data.scenario_id` on every push, it is what
  /// telemetry rows join on, and the server reads it. A field renamed for a protocol
  /// reason would silently repoint that scenario's prose at a key the CSV does not
  /// have, and the failure would surface as a missing translation rather than as the
  /// wire change it was. Two names that happen to match are cheaper than one name
  /// serving two masters.
  final String l10nKey;

  /// The single letter its source table is filed under — `'A'` through `'K'`.
  ///
  /// The display name that letter expands to (`'A — Basic delivery'`) is prose now,
  /// read through `ScenarioText.scenarioGroupName` in the app; this field stays a
  /// bare letter so grouping and ordering do not depend on the translations.
  final String group;

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

  /// Who to deliver to, or null for this device, which is what all but four
  /// scenarios want.
  final SendTarget? target;

  bool get isSupported => needs.isEmpty;
}
