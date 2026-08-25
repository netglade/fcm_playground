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
    expectation:
        'Data-only, so the app draws it and posts the summary in every state — '
        'FCM has no `group` field, so a notification-block payload would leave '
        'the summary code unreached whenever the app is backgrounded. The app '
        'posts the summary itself and updates its count as each one arrives — '
        'the payload only names the group. Send it several times to watch the '
        'count climb.',
    payloadTemplate: {
      'data': {'title': 'Build 128', 'body': 'Passed.', 'group': 'builds'},
    },
  ),
  Scenario(
    id: 'g2_update_same_id',
    group: 'G — Groups, badge, updates',
    title: 'Replacing a notification in place',
    description:
        'Send twice with the same tag. Watch that the second replaces the first '
        'rather than stacking, and whether it re-alerts.',
    expectation:
        'FCM honours android.notification.tag itself when it draws the tray '
        'entry, and the app now keys its own drawing on the same tag — so the '
        'second send replaces the first whichever of them drew it.',
    payloadTemplate: {
      'notification': {'title': 'Build 128', 'body': 'Running…'},
      'android': {
        'notification': {'tag': 'build-128'},
      },
    },
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
        // apns.payload is forwarded to Apple verbatim, so its numbers stay
        // numbers: `'badge': 7`, never `'7'`. It is also the nested-APNs fixture
        // the Sandbox's dotted-path form test reads, so the alert must stay a
        // nested object.
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
