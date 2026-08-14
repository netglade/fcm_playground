import 'scenario.dart';
import 'scenario_need.dart';

/// **G — Groups, badge and updates.** Several notifications behaving as one.
///
/// The badge is the wildest thing in this catalogue: Android has no standard for
/// it, so One UI, MIUI and the Pixel launcher each do something different with
/// the same `notification_count`, and some ignore it entirely. iOS, by contrast,
/// has exactly one well-defined answer — `aps.badge` — which is why g4 works
/// today and g3 does not.
const groupG = <Scenario>[
  Scenario(
    id: 'g1_group_summary',
    group: 'G — Groups, badge, updates',
    title: 'Five notifications with a summary',
    description:
        'Watch that they collapse under one summary row, and what the summary '
        'says when the fifth arrives.',
    payloadTemplate: {
      'notification': {'title': 'Build 128', 'body': 'Passed.'},
      'android': {
        'notification': {'tag': 'builds-group', 'channel_id': 'builds'},
      },
      'data': {'group': 'builds', 'group_summary': 'false'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'g2_update_same_id',
    group: 'G — Groups, badge, updates',
    title: 'Replacing a notification in place',
    description:
        'Send twice with the same tag. Watch that the second replaces the first '
        'rather than stacking, and whether it re-alerts.',
    payloadTemplate: {
      'notification': {'title': 'Build 128', 'body': 'Running…'},
      'android': {
        'notification': {'tag': 'build-128'},
      },
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'g3_badge',
    group: 'G — Groups, badge, updates',
    title: 'A count on the launcher icon',
    description:
        'The least portable thing here. Watch whether the launcher shows the '
        'number, a dot, or nothing at all.',
    expectation:
        'Behaviour differs per manufacturer: One UI, MIUI and the Pixel '
        'launcher all disagree, and several require the user to enable badges '
        'per app.',
    payloadTemplate: {
      'notification': {'title': 'Five waiting', 'body': 'Check the launcher.'},
      // notification_count is a typed int32 on FCM's AndroidNotification, so 5
      // rather than '5' — unlike the `data` map, which is map<string, string>.
      'android': {
        'notification': {'notification_count': 5},
      },
    },
    needs: [ScenarioNeed.badge],
  ),
  Scenario(
    id: 'g4_badge_ios',
    group: 'G — Groups, badge, updates',
    title: 'The iOS badge via aps.badge',
    description:
        'One well-defined number, set by the sender. Watch that it replaces '
        'rather than increments — iOS does not add.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        // apns.payload is forwarded to Apple verbatim, so it is free-form and
        // its numbers stay numbers: `'badge': 7`, never `'7'`. This entry is
        // also the source of the nested-APNs fixture the Sandbox's dotted-path
        // form test reads, so the alert stays a nested object rather than the
        // flat string APNs would also accept.
        'payload': {
          'aps': {
            'alert': {'title': 'Five waiting', 'body': 'Badge set to 7.'},
            'badge': 7,
            'sound': 'default',
          },
        },
      },
    },
  ),
];
