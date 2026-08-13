import 'scenario.dart';
import 'scenario_need.dart';

/// **C — Priority and delivery window.** How hard FCM tries, and for how long.
///
/// The group that explains most "it arrived twenty minutes late" reports: NORMAL
/// priority may wait for a maintenance window, and Doze extends that window a
/// long way. The last two are adb commands rather than payloads, because Doze
/// cannot be entered by asking politely.
const groupC = <Scenario>[
  Scenario(
    id: 'c1_priority_high',
    group: 'C — Priority and delivery window',
    title: 'android.priority HIGH',
    description:
        'Wakes a dozing device. Watch how quickly it lands with the screen off '
        'compared with c2.',
    payloadTemplate: {
      'notification': {'title': 'High priority', 'body': 'Should wake now.'},
      'android': {'priority': 'HIGH'},
    },
  ),
  Scenario(
    id: 'c2_priority_normal',
    group: 'C — Priority and delivery window',
    title: 'android.priority NORMAL',
    description:
        'May wait for the next maintenance window. Watch for a delay with the '
        'screen off — this is the usual cause of a "missing" push.',
    payloadTemplate: {
      'notification': {'title': 'Normal priority', 'body': 'May be held.'},
      'android': {'priority': 'NORMAL'},
    },
  ),
  Scenario(
    id: 'c3_ttl_zero',
    group: 'C — Priority and delivery window',
    title: 'android.ttl 0s — now or never',
    description:
        'FCM makes one attempt and discards the message if the device is not '
        'reachable. Watch that an offline device never receives it.',
    payloadTemplate: {
      'notification': {'title': 'Now or never', 'body': 'ttl 0s.'},
      'android': {'priority': 'HIGH', 'ttl': '0s'},
    },
  ),
  Scenario(
    id: 'c4_ttl_long',
    group: 'C — Priority and delivery window',
    title: 'android.ttl 86400s — a day of retries',
    description:
        'Held for 24 hours. Watch it arrive when the network comes back, long '
        'after it was sent.',
    payloadTemplate: {
      'notification': {'title': 'Patient', 'body': 'ttl 86400s.'},
      'android': {'priority': 'HIGH', 'ttl': '86400s'},
    },
  ),
  Scenario(
    id: 'c5_collapse_key',
    group: 'C — Priority and delivery window',
    title: 'Five sends sharing a collapse_key, offline',
    description:
        'Only the last should survive. Watch that one notification appears, not '
        'five, once the network returns.',
    payloadTemplate: {
      'notification': {'title': 'Collapsible', 'body': 'Only the last one.'},
      'android': {'priority': 'HIGH', 'collapse_key': 'builds'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Put the device in airplane mode. Send five times, changing the body '
        'each time. Restore the network: exactly one notification should appear, '
        'carrying the last body.',
  ),
  Scenario(
    id: 'c6_doze_test',
    group: 'C — Priority and delivery window',
    title: 'Delivery while the device is in Doze',
    description:
        'Real Doze behaviour, not a simulation. Watch which priorities break '
        'through and which are held.',
    payloadTemplate: {
      'notification': {
        'title': 'Doze probe',
        'body': 'Did this break through?',
      },
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell dumpsys deviceidle force-idle — send, then '
        'adb shell dumpsys deviceidle unforce to restore.',
  ),
  Scenario(
    id: 'c7_standby_bucket',
    group: 'C — Priority and delivery window',
    title: 'App in the restricted standby bucket',
    description:
        'The harshest state Android imposes on an unused app. Watch whether a '
        'HIGH priority push still arrives.',
    payloadTemplate: {
      'notification': {'title': 'Restricted', 'body': 'Bucket probe.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — check '
        'with adb shell am get-standby-bucket cz.netglade.fcm_app.',
  ),
];
