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
    l10nKey: 'c1_priority_high',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'High priority', 'body': 'Should wake now.'},
      'android': {'priority': 'HIGH'},
    },
  ),
  Scenario(
    id: 'c2_priority_normal',
    l10nKey: 'c2_priority_normal',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'Normal priority', 'body': 'May be held.'},
      'android': {'priority': 'NORMAL'},
    },
  ),
  Scenario(
    id: 'c3_ttl_zero',
    l10nKey: 'c3_ttl_zero',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'Now or never', 'body': 'ttl 0s.'},
      'android': {'priority': 'HIGH', 'ttl': '0s'},
    },
  ),
  Scenario(
    id: 'c4_ttl_long',
    l10nKey: 'c4_ttl_long',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'Patient', 'body': 'ttl 86400s.'},
      'android': {'priority': 'HIGH', 'ttl': '86400s'},
    },
  ),
  Scenario(
    id: 'c5_collapse_key',
    l10nKey: 'c5_collapse_key',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'Collapsible', 'body': 'Only the last one.'},
      'android': {'priority': 'HIGH', 'collapse_key': 'builds'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
  Scenario(
    id: 'c6_doze_test',
    l10nKey: 'c6_doze_test',
    group: 'C',
    payloadTemplate: {
      'notification': {
        'title': 'Doze probe',
        'body': 'Did this break through?',
      },
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
  Scenario(
    id: 'c7_standby_bucket',
    l10nKey: 'c7_standby_bucket',
    group: 'C',
    payloadTemplate: {
      'notification': {'title': 'Restricted', 'body': 'Bucket probe.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
];
