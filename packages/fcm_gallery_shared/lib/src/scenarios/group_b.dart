import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';
import 'package:fcm_gallery_shared/src/scenarios/scenario_need.dart';

/// **B — Application states.** The same push, delivered into six different
/// conditions of the app.
///
/// Nothing here varies the payload: every difference is in what the app is doing
/// when the message lands. That is why five of the six carry a manual step — no
/// payload can kill an app, reboot a phone or revoke a permission.
const groupB = <Scenario>[
  Scenario(
    id: 'b1_foreground',
    l10nKey: 'b1_foreground',
    group: 'B',
    payloadTemplate: {
      'notification': {'title': 'Foreground', 'body': 'Drawn by the app.'},
      'data': {'event': 'foreground'},
    },
  ),
  Scenario(
    id: 'b2_background',
    l10nKey: 'b2_background',
    group: 'B',
    payloadTemplate: {
      'notification': {'title': 'Backgrounded', 'body': 'Drawn by Android.'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
  Scenario(
    id: 'b3_killed',
    l10nKey: 'b3_killed',
    group: 'B',
    payloadTemplate: {
      'data': {'event': 'killed_probe', 'sent_at_stage': 'killed'},
      'android': {'priority': 'HIGH'},
    },
    requiresKilledApp: true,
    defaultDelaySeconds: 20,
  ),
  Scenario(
    id: 'b4_after_reboot',
    l10nKey: 'b4_after_reboot',
    group: 'B',
    payloadTemplate: {
      'notification': {'title': 'After reboot', 'body': 'Did this arrive?'},
      'android': {'priority': 'HIGH', 'direct_boot_ok': true},
    },
    needs: [ScenarioNeed.manualStep],
  ),
  Scenario(
    id: 'b5_force_stopped',
    l10nKey: 'b5_force_stopped',
    group: 'B',
    payloadTemplate: {
      'notification': {'title': 'Force stopped', 'body': 'Should not arrive.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
  Scenario(
    id: 'b6_token_refresh',
    l10nKey: 'b6_token_refresh',
    group: 'B',
    payloadTemplate: {
      'notification': {'title': 'Token check', 'body': 'Which token got this?'},
    },
    needs: [ScenarioNeed.manualStep],
  ),
];
