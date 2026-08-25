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
    l10nKey: 'g1_group_summary',
    group: 'G',
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
    l10nKey: 'g2_update_same_id',
    group: 'G',
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
    l10nKey: 'g3_badge',
    group: 'G',
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
    l10nKey: 'g4_badge_ios',
    group: 'G',
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
