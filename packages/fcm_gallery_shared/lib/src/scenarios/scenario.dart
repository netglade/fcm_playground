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
    this.tags = const [],
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

  /// Free-form labels shown as chips: platform names, features.
  final List<String> tags;

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

/// The nine payload templates the Sandbox offers, grouped by the facet of FCM
/// each one demonstrates.
///
/// Every template here round-trips through [FcmMessage.fromJson] and
/// `FcmMessage.toJson` unchanged — that is what proves the typed model built
/// in Tasks 1–7 is a faithful mirror of what Google's FCM v1 reference
/// actually accepts.
const scenarioGallery = <Scenario>[
  Scenario(
    id: 'big_picture_remote',
    group: 'Appearance',
    title: 'Notification with an image',
    description:
        'Sends a notification carrying a remote image URL. Watch that the '
        'image itself downloads and renders, not just the title and body.',
    expectation: 'On some Xiaomi and Huawei builds the image may not appear.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
        'image': 'https://picsum.photos/600/300',
      },
    },
    tags: ['android', 'ios', 'image'],
  ),
  Scenario(
    id: 'coloured_icon',
    group: 'Appearance',
    title: 'Coloured small icon',
    description:
        'Sends a notification with an Android small icon and accent colour '
        'set. Watch that the status bar icon tints to the requested colour.',
    expectation:
        'The icon must exist as a drawable in the app; Android falls back to '
        'the launcher icon otherwise.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
      'android': {
        'notification': {'icon': 'ic_stat_build', 'color': '#4285f4'},
      },
    },
    tags: ['android', 'icon'],
  ),
  Scenario(
    id: 'custom_channel',
    group: 'Appearance',
    title: 'High-importance channel',
    description:
        'Sends a notification routed to a named Android channel. Watch that '
        'it pops as a heads-up banner rather than landing silently in the '
        'shade.',
    expectation:
        'The channel must already exist. Android silently uses the default '
        'channel for an unknown id.',
    payloadTemplate: {
      'notification': {
        'title': 'Heads up',
        'body': 'This should pop as a banner.',
      },
      'android': {
        'notification': {'channel_id': 'fcm_sample_high'},
      },
    },
    tags: ['android', 'channel'],
  ),
  Scenario(
    id: 'high_priority',
    group: 'Delivery',
    title: 'High priority',
    description:
        'Sends a notification with Android priority set to HIGH. Watch that '
        'it arrives immediately, even on a dozing device.',
    payloadTemplate: {
      'notification': {
        'title': 'High priority',
        'body': 'Should arrive at once.',
      },
      'android': {'priority': 'HIGH'},
    },
    tags: ['android', 'priority'],
  ),
  Scenario(
    id: 'normal_priority_long_ttl',
    group: 'Delivery',
    title: 'Normal priority, one hour TTL',
    description:
        'Sends a notification with Android priority set to NORMAL and a one '
        'hour time-to-live. Watch how long delivery is held, not just whether '
        'it arrives.',
    expectation:
        'A dozing device may hold this until its next maintenance window, so '
        'minutes is normal.',
    payloadTemplate: {
      'notification': {
        'title': 'Normal priority',
        'body': 'May be held for a while.',
      },
      'android': {'priority': 'NORMAL', 'ttl': '3600s'},
    },
    tags: ['android', 'priority', 'ttl'],
  ),
  Scenario(
    id: 'collapsible',
    group: 'Delivery',
    title: 'Collapsible',
    description:
        'Sends a notification with a collapse key. Watch that sending it '
        'twice while offline leaves only the newest one on the device.',
    expectation:
        'Send twice while the device is offline; only the last should arrive.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Only the newest should arrive.',
      },
      'android': {'collapse_key': 'builds'},
    },
    tags: ['android', 'collapse'],
  ),
  Scenario(
    id: 'data_only',
    group: 'Data',
    title: 'Data-only, silent',
    description:
        'Sends a data payload with no notification block. Watch that no '
        'banner is drawn at all, and that the data still reaches the app.',
    expectation:
        'No notification is drawn. It appears in the inbox with empty text '
        'and its data keys.',
    payloadTemplate: {
      'data': {'event': 'sync', 'build_number': '128'},
      'android': {'priority': 'HIGH'},
    },
    requiresKilledApp: true,
    defaultDelaySeconds: 10,
    tags: ['android', 'ios', 'data', 'silent'],
  ),
  Scenario(
    id: 'notification_and_data',
    group: 'Data',
    title: 'Notification plus data',
    description:
        'Sends a notification alongside a data payload. Watch that both the '
        'banner and the data keys arrive together, and that tapping the '
        'banner exposes the data to the app.',
    payloadTemplate: {
      'notification': {'title': 'Build finished', 'body': 'Tap to open it.'},
      'data': {'event': 'build_finished', 'deep_link': '/builds/128'},
    },
    tags: ['android', 'ios', 'data'],
  ),
  Scenario(
    id: 'apns_alert',
    group: 'iOS',
    title: 'APNs alert with a badge',
    description:
        'Sends an APNs alert with an immediate-priority header and a badge '
        'count. Watch that the alert, sound and badge all show on the app '
        'icon.',
    expectation:
        'Unverified here — this machine has no Xcode and no iOS device.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {
              'title': 'Build finished',
              'body': 'Release 1.0.0 is ready.',
            },
            'badge': 1,
            'sound': 'default',
          },
        },
      },
    },
    tags: ['ios', 'apns'],
  ),
];
