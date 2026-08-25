import 'scenario.dart';
import 'scenario_need.dart';

/// **F — Interaction.** What happens when the user touches it, or does not.
///
/// FCM has no field for any of this: action buttons, inline replies and
/// full-screen intents are all built by the client from `data`. The three
/// deep-link scenarios are separated by app state on purpose — foreground,
/// background and killed take three different code paths
/// (`onMessage`, `onMessageOpenedApp`, `getInitialMessage`), and the third is
/// where most routing bugs live because it is the one that is easy to forget.
const groupF = <Scenario>[
  Scenario(
    id: 'f1_actions',
    l10nKey: 'f1_actions',
    group: 'F',
    payloadTemplate: {
      'data': {
        'title': 'Build failed',
        'body': 'Retry or open?',
        'actions': 'retry:Retry|open:Open build',
        'build': '128',
      },
    },
  ),
  Scenario(
    id: 'f2_inline_reply',
    l10nKey: 'f2_inline_reply',
    group: 'F',
    payloadTemplate: {
      'data': {
        'title': 'Ada',
        'body': 'ready when you are',
        'actions': 'reply:Reply:input',
        'reply_to': 'thread-42',
      },
    },
  ),
  Scenario(
    id: 'f3_deeplink_foreground',
    l10nKey: 'f3_deeplink_foreground',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Open telemetry', 'body': 'Tap to route.'},
      'data': {'deep_link': '/telemetry'},
    },
  ),
  Scenario(
    id: 'f4_deeplink_background',
    l10nKey: 'f4_deeplink_background',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Open sandbox', 'body': 'Tap to route.'},
      'data': {'deep_link': '/sandbox'},
    },
  ),
  Scenario(
    id: 'f5_deeplink_killed',
    l10nKey: 'f5_deeplink_killed',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Open runs', 'body': 'Tap to route.'},
      'data': {'deep_link': '/runs'},
    },
    requiresKilledApp: true,
    defaultDelaySeconds: 20,
  ),
  Scenario(
    id: 'f6_delete_intent',
    l10nKey: 'f6_delete_intent',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Dismiss me', 'body': 'Swipe, do not tap.'},
      'data': {'track_dismiss': 'true'},
    },
  ),
  Scenario(
    id: 'f7_ongoing',
    l10nKey: 'f7_ongoing',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Syncing', 'body': 'Cannot be dismissed.'},
      'data': {'ongoing': 'true'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f8_full_screen_intent',
    l10nKey: 'f8_full_screen_intent',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Incoming call', 'body': 'Ada is calling.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'calls'},
      },
      'data': {'full_screen': 'true', 'caller': 'Ada'},
    },
    needs: [ScenarioNeed.interaction, ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'f9_trampoline',
    l10nKey: 'f9_trampoline',
    group: 'F',
    payloadTemplate: {
      'notification': {'title': 'Trampoline', 'body': 'This should not work.'},
      'data': {'trampoline': 'true', 'deep_link': '/builds/125'},
    },
    needs: [ScenarioNeed.interaction],
  ),
];
