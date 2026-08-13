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
    group: 'F — Interaction',
    title: 'Two or three action buttons',
    description:
        'Watch whether the buttons survive a reboot of the notification shade, '
        'and what happens to the notification when one is pressed.',
    payloadTemplate: {
      'notification': {'title': 'Build failed', 'body': 'Retry or open?'},
      'data': {'actions': 'retry:Retry|open:Open build', 'build': '128'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f2_inline_reply',
    group: 'F — Interaction',
    title: 'Inline reply with RemoteInput',
    description:
        'Type a reply without opening the app. Watch that the notification '
        'shows a sending state and then updates.',
    payloadTemplate: {
      'notification': {'title': 'Ada', 'body': 'ready when you are'},
      'data': {'reply_to': 'thread-42', 'actions': 'reply:Reply'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f3_deeplink_foreground',
    group: 'F — Interaction',
    title: 'Tap while the app is running',
    description:
        'Routing from onMessage, with the app already on screen. Watch that the '
        'current screen is not lost.',
    payloadTemplate: {
      'notification': {'title': 'Open build 128', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/128'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f4_deeplink_background',
    group: 'F — Interaction',
    title: 'Tap while the app is backgrounded',
    description:
        'Routing from onMessageOpenedApp. Watch that the app resumes on the '
        'linked screen rather than where it was left.',
    payloadTemplate: {
      'notification': {'title': 'Open build 127', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/127'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f5_deeplink_killed',
    group: 'F — Interaction',
    title: 'Tap with the app killed',
    description:
        'Routing from getInitialMessage, which runs once at startup and is the '
        'commonest source of deep-link bugs — it is easy to forget, and it fails '
        'only in the one state nobody tests by hand.',
    payloadTemplate: {
      'notification': {'title': 'Open build 126', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/126'},
    },
    // delayedSend as well as interaction: requiresKilledApp means the scenario
    // is meaningless in any other state, and arranging that means holding the
    // send until the app is gone.
    needs: [ScenarioNeed.interaction, ScenarioNeed.delayedSend],
    requiresKilledApp: true,
    defaultDelaySeconds: 20,
  ),
  Scenario(
    id: 'f6_delete_intent',
    group: 'F — Interaction',
    title: 'Detecting a swipe-away',
    description:
        'The delete intent fires when the user dismisses without tapping. Watch '
        'that it is distinguishable from a tap.',
    payloadTemplate: {
      'notification': {'title': 'Dismiss me', 'body': 'Swipe, do not tap.'},
      'data': {'track_dismiss': 'true'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f7_ongoing',
    group: 'F — Interaction',
    title: 'An ongoing, undismissable notification',
    description:
        'Watch that it cannot be swiped away, and confirm there is a way to '
        'clear it — an ongoing notification with no exit is a support ticket.',
    payloadTemplate: {
      'notification': {'title': 'Syncing', 'body': 'Cannot be dismissed.'},
      'data': {'ongoing': 'true'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f8_full_screen_intent',
    group: 'F — Interaction',
    title: 'Full-screen intent, as an incoming call',
    description:
        'Takes over the lock screen. Watch whether it is granted at all, and '
        'what it degrades to when it is refused.',
    expectation:
        'Needs the USE_FULL_SCREEN_INTENT permission, which Android 14+ grants '
        'only to calling and alarm apps. Expect a degraded heads-up notification '
        'rather than a takeover here.',
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
    group: 'F — Interaction',
    title: 'A notification trampoline, which should fail',
    description:
        'Starting an activity from a service or broadcast receiver after a tap. '
        'Banned since Android 12. Watch for the failure and its log line.',
    expectation:
        'Expected to fail on Android 12 and later. The demonstration is the '
        'error, not a working route.',
    payloadTemplate: {
      'notification': {'title': 'Trampoline', 'body': 'This should not work.'},
      'data': {'trampoline': 'true', 'deep_link': '/builds/125'},
    },
    needs: [ScenarioNeed.interaction],
  ),
];
