import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';
import 'package:fcm_gallery_shared/src/scenarios/scenario_need.dart';

/// **H — Intrusive and priority.** Breaking through the user's quiet.
///
/// Android and iOS solve this differently, and the split shows: on Android the
/// power to bypass Do Not Disturb is a *channel* property needing the user's
/// policy consent, while on iOS it is a per-message `interruption-level` inside
/// the free-form `aps` dictionary — which is precisely why `apns.payload` is left
/// untyped in this repo's model.
const groupH = <Scenario>[
  Scenario(
    id: 'h1_dnd_bypass',
    l10nKey: 'h1_dnd_bypass',
    group: 'H',
    payloadTemplate: {
      'notification': {'title': 'Urgent', 'body': 'Should sound during DND.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'dnd_bypass'},
      },
    },
    needs: [ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'h2_category_alarm',
    l10nKey: 'h2_category_alarm',
    group: 'H',
    payloadTemplate: {
      'notification': {'title': 'Alarm', 'body': 'Categorised as an alarm.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'alarms'},
      },
      'data': {'category': 'alarm'},
    },
  ),
  Scenario(
    id: 'h3_ios_time_sensitive',
    l10nKey: 'h3_ios_time_sensitive',
    group: 'H',
    payloadTemplate: {
      // apns.headers is a typed map<string, string>, so the priority is '10',
      // never a bare 10 — and 10 is what an alerting interruption level needs:
      // at 5 APNs may hold the push, which is exactly the behaviour this entry
      // is meant to break past.
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': 'Time sensitive', 'body': 'Through Focus.'},
            'interruption-level': 'time-sensitive',
            'sound': 'default',
          },
        },
      },
    },
  ),
  Scenario(
    id: 'h4_ios_critical',
    l10nKey: 'h4_ios_critical',
    group: 'H',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        // apns.payload is forwarded verbatim, so its numbers keep the type they
        // are written with. APNs defines `critical` as the int flag 1 and `volume`
        // as a double, so the two differ deliberately: 1 and 1.0.
        'payload': {
          'aps': {
            'alert': {'title': 'Critical', 'body': 'Through the mute switch.'},
            'interruption-level': 'critical',
            'sound': {'critical': 1, 'name': 'default', 'volume': 1.0},
          },
        },
      },
    },
    needs: [ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'h5_ios_passive',
    l10nKey: 'h5_ios_passive',
    group: 'H',
    payloadTemplate: {
      // Priority 5 rather than 10, and no sound key at all: passive claims "no
      // sound, no wake", so anything that alerts would make this entry
      // indistinguishable from h3 on the device.
      'apns': {
        'headers': {'apns-priority': '5'},
        'payload': {
          'aps': {
            'alert': {'title': 'Passive', 'body': 'No alert at all.'},
            'interruption-level': 'passive',
          },
        },
      },
    },
  ),
];
