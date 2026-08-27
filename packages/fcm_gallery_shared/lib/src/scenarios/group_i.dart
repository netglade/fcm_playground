import 'scenario.dart';
import 'scenario_need.dart';

/// **I — Silent and data.** Delivery the user is not meant to notice.
///
/// The distinction that matters here is *visible but quiet* versus *no text to
/// read*: i1 posts a real banner through a low-importance channel, while i2's
/// payload carries no title or body, so what appears is a blank tray entry
/// rather than a wholly absent one. i4 is the odd one out: twenty pushes in ten
/// seconds is about rate limiting, and MIUI in particular will start dropping
/// them.
const groupI = <Scenario>[
  Scenario(
    id: 'i1_silent_no_sound',
    l10nKey: 'i1_silent_no_sound',
    group: 'I',
    payloadTemplate: {
      'notification': {'title': 'Quiet', 'body': 'Seen, not heard.'},
      'android': {
        'notification': {'channel_id': 'importance_low'},
      },
    },
  ),
  Scenario(
    id: 'i2_silent_data_sync',
    l10nKey: 'i2_silent_data_sync',
    group: 'I',
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
    group: 'I',
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
    group: 'I',
    payloadTemplate: {
      'notification': {'title': 'Burst', 'body': 'One of twenty.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
];
