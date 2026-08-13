import 'scenario.dart';
import 'scenario_need.dart';

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
    group: 'H — Intrusive and priority',
    title: 'A channel that bypasses Do Not Disturb',
    description:
        'Watch that it sounds while DND is on. Setting the flag is not enough — '
        'the user must have granted notification-policy access.',
    expectation:
        'Requires Notification Policy Access, granted by the user in system '
        'settings. Without it the flag is accepted and silently ignored.',
    payloadTemplate: {
      'notification': {'title': 'Urgent', 'body': 'Should sound during DND.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'dnd_bypass'},
      },
    },
    needs: [ScenarioNeed.channels, ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'h2_category_alarm',
    group: 'H — Intrusive and priority',
    title: 'CATEGORY_ALARM',
    description:
        'Alarms are treated as a special class by DND. Watch whether the '
        'category alone changes anything without policy access.',
    expectation:
        'FCM has no field for the notification category — it is set by the client '
        'when building the local notification, which is why this needs the '
        'channel work.',
    payloadTemplate: {
      'notification': {'title': 'Alarm', 'body': 'Categorised as an alarm.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'alarms'},
      },
      'data': {'category': 'alarm'},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'h3_ios_time_sensitive',
    group: 'H — Intrusive and priority',
    title: 'iOS time-sensitive — breaks through Focus',
    description:
        'Watch that it arrives during a Focus mode that would hold an ordinary '
        'notification.',
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
    group: 'H — Intrusive and priority',
    title: 'iOS critical — through Focus and the mute switch',
    description:
        'The most intrusive delivery Apple offers. Watch that it sounds even '
        'when the device is muted.',
    expectation:
        'Requires a critical-alert entitlement that Apple must approve for the '
        'app. Without it APNs rejects the push, so this stays untestable here — '
        'listed for completeness rather than scheduled.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        // apns.payload is forwarded to Apple verbatim, so it is free-form and
        // its numbers keep the type they are written with. APNs defines
        // `critical` as the int flag 1 and `volume` as a double in 0.0–1.0, so
        // the two differ deliberately: 1 and 1.0, not 1.0 and 1.
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
    group: 'H — Intrusive and priority',
    title: 'iOS passive — no sound, no wake',
    description:
        'The quietest level: it appears in the list without alerting. Watch that '
        'the screen does not light up.',
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
