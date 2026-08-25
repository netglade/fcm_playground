import 'scenario.dart';
import 'scenario_need.dart';

/// **I — Silent and data.** Delivery the user is not meant to notice.
///
/// The distinction that matters here is *visible but quiet* versus *no text to
/// read*: i1 posts a real banner through a low-importance channel, while i2's
/// payload carries no title or body, so what appears is a blank tray entry
/// rather than a wholly absent one. The first is a channel-importance question
/// and so is blocked; the second is just a `data` payload and works today. i4 is
/// the odd one out: twenty pushes in ten seconds is about rate limiting, and
/// MIUI in particular will start dropping them.
const groupI = <Scenario>[
  Scenario(
    id: 'i1_silent_no_sound',
    l10nKey: 'i1_silent_no_sound',
    group: 'I — Silent and data',
    title: 'Visible but silent',
    description:
        'Appears in the tray with no sound and no vibration. Watch that it is '
        'silent but still lights the screen or not.',
    payloadTemplate: {
      'notification': {'title': 'Quiet', 'body': 'Seen, not heard.'},
      'android': {
        'notification': {'channel_id': 'importance_low'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'i2_silent_data_sync',
    l10nKey: 'i2_silent_data_sync',
    group: 'I — Silent and data',
    title: 'Silent sync, drawn blank',
    description:
        'The handler writes a row; that is the effect this scenario is about. '
        'A tray entry still appears — icon and app name, no title or body — '
        'since nothing suppresses a titleless banner. Watch the Inbox page for '
        'the row; the tray entry has no text to read.',
    // `data` is deliberately the only block: anything under `notification` or
    // `android.notification` would be drawn by the system and this would stop
    // being a silent sync. FCM's data map is map<string, string>, so the cursor
    // is a string timestamp rather than a number.
    payloadTemplate: {
      'data': {
        'event': 'sync',
        'entity': 'builds',
        'cursor': '2026-08-13T09:30:00Z',
      },
    },
  ),
  Scenario(
    id: 'i3_ios_content_available',
    l10nKey: 'i3_ios_content_available',
    group: 'I — Silent and data',
    title: 'iOS background refresh via content-available',
    description:
        'Wakes the app to fetch without showing anything. Watch how often iOS '
        'actually honours it — it throttles this aggressively.',
    expectation:
        'iOS may delay or drop these entirely depending on battery and usage. A '
        'missed one is not necessarily a bug.',
    payloadTemplate: {
      'apns': {
        // The pair Apple documents for a background push: apns-push-type says
        // what kind of push this is, and apns-priority 5 is the only priority
        // APNs accepts for a background one. apns.headers is a typed
        // map<string, string>, so the priority is '5' and never a bare 5.
        'headers': {'apns-priority': '5', 'apns-push-type': 'background'},
        // apns.payload is forwarded verbatim, so its numbers keep the type they
        // are written with, and APNs defines content-available as the integer 1.
        // Written 1.0 it would round-trip unchanged and arrive as something APNs
        // ignores.
        'payload': {
          'aps': {'content-available': 1},
        },
      },
      'data': {'event': 'sync'},
    },
  ),
  Scenario(
    id: 'i4_burst',
    l10nKey: 'i4_burst',
    group: 'I — Silent and data',
    title: 'Twenty messages in ten seconds',
    description:
        'Watch for rate limiting, coalescing, and manufacturer caps. MIUI will '
        'usually start dropping before FCM does.',
    payloadTemplate: {
      'notification': {'title': 'Burst', 'body': 'One of twenty.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Send this 20 times within 10 seconds and count what arrives. Vary the '
        'body so collapsing is visible.',
  ),
];
