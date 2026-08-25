import 'scenario.dart';
import 'scenario_need.dart';

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
    group: 'B — Application states',
    title: 'Delivered with the app in the foreground',
    description:
        'onMessage fires and nothing is drawn by the system, so the app must '
        'draw it. Watch that a banner appears at all.',
    payloadTemplate: {
      'notification': {'title': 'Foreground', 'body': 'Drawn by the app.'},
      'data': {'event': 'foreground'},
    },
  ),
  Scenario(
    id: 'b2_background',
    l10nKey: 'b2_background',
    group: 'B — Application states',
    title: 'App backgrounded, screen locked',
    description:
        'The system draws this one. Watch whether it reaches the lock screen '
        'and how much of it is shown there.',
    payloadTemplate: {
      'notification': {'title': 'Backgrounded', 'body': 'Drawn by Android.'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Background the app with the home button, then lock the screen. Send '
        'from another machine, or use validate-only first to check the payload.',
  ),
  Scenario(
    id: 'b3_killed',
    l10nKey: 'b3_killed',
    group: 'B — Application states',
    title: 'App swiped out of recents',
    description:
        'The hardest case, and the reason delayed sending exists: the send has '
        'to happen after the app is gone. Watch whether the data handler runs.',
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
    group: 'B — Application states',
    title: 'After a reboot, app never opened',
    description:
        'Until the app is opened once after boot, some manufacturers hold its '
        'background work entirely. Watch whether anything arrives.',
    payloadTemplate: {
      'notification': {'title': 'After reboot', 'body': 'Did this arrive?'},
      'android': {'priority': 'HIGH', 'direct_boot_ok': true},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb reboot — then do NOT open the app. Wait for the lock screen and '
        'send.',
  ),
  Scenario(
    id: 'b5_force_stopped',
    l10nKey: 'b5_force_stopped',
    group: 'B — Application states',
    title: 'After Force stop',
    description:
        "Force stop revokes the app's ability to be woken. This scenario "
        'exists to prove we know that, rather than to be debugged.',
    expectation:
        'Expected to arrive: nothing. A force-stopped app receives no pushes at '
        'all until it is launched by hand. If something does arrive, that is the '
        'surprise worth investigating.',
    payloadTemplate: {
      'notification': {'title': 'Force stopped', 'body': 'Should not arrive.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Force stop. Then send, and expect '
        'nothing.',
  ),
  Scenario(
    id: 'b6_token_refresh',
    l10nKey: 'b6_token_refresh',
    group: 'B — Application states',
    title: 'Token rotated by a reinstall or clear-data',
    description:
        'The old token is dead and sending to it must fail loudly. Watch the '
        'Inbox page for the new token, and compare it with the old one.',
    payloadTemplate: {
      'notification': {'title': 'Token check', 'body': 'Which token got this?'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell pm clear cz.netglade.fcm_app — reopen the app and read the '
        'new token off the Inbox page. Sending to the old one should give '
        'UNREGISTERED, which is k2_invalid_token.',
  ),
];
