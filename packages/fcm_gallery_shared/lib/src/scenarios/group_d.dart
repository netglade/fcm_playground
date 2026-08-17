import 'scenario.dart';
import 'scenario_need.dart';

/// **D — Channels and importance.** What the user, not the sender, controls.
///
/// Importance is a property of the *channel*, set once when it is created and
/// immutable thereafter — so the only fix is a new channel with a new id, which is
/// why d7 exists and why channels get versioned names like `chat_v2`.
///
/// None of these demonstrates anything until the app registers the channels and
/// shows each one's importance *as read back from the system* — reading it from our
/// own code would only tell us what we asked for.
const groupD = <Scenario>[
  Scenario(
    id: 'd1_importance_high',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_HIGH — heads-up banner',
    description:
        'Watch for a banner that floats over the current app, with sound.',
    payloadTemplate: {
      'notification': {'title': 'Heads up', 'body': 'Importance high.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'importance_high'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd2_importance_default',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_DEFAULT — sound, no banner',
    description: 'Watch for a sound and a tray entry, but nothing floating.',
    payloadTemplate: {
      'notification': {'title': 'Default', 'body': 'Sound, no banner.'},
      'android': {
        'notification': {'channel_id': 'importance_default'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd3_importance_low',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_LOW — silent',
    description:
        'Visible but with no sound and no vibration. Watch that it is genuinely '
        'silent rather than quiet.',
    payloadTemplate: {
      'notification': {'title': 'Low', 'body': 'No sound, no vibration.'},
      'android': {
        'notification': {'channel_id': 'importance_low'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd4_importance_min',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_MIN — status bar only',
    description:
        'No icon in the status bar on some versions; only in the shade. Watch '
        'where it appears at all.',
    payloadTemplate: {
      'notification': {'title': 'Min', 'body': 'Shade only.'},
      'android': {
        'notification': {'channel_id': 'importance_min'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd5_custom_sound',
    group: 'D — Channels and importance',
    title: 'A custom sound on the channel',
    description:
        'The sound is a channel property, so changing it needs a new channel. '
        'Watch that the custom sound plays rather than the default.',
    expectation:
        'The named resource must exist in android/app/src/main/res/raw. A '
        'missing file falls back to the default sound silently.',
    payloadTemplate: {
      'notification': {'title': 'Custom sound', 'body': 'Should chime.'},
      'android': {
        'notification': {'channel_id': 'custom_sound', 'sound': 'chime'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd6_vibration_pattern',
    group: 'D — Channels and importance',
    title: 'A custom vibration pattern',
    description:
        'Alternating vibrate and pause durations. Watch that the pattern is the '
        'one asked for rather than the channel default.',
    payloadTemplate: {
      'notification': {'title': 'Buzz', 'body': 'Short, long, short.'},
      'android': {
        'notification': {
          'channel_id': 'vibration_pattern',
          'default_vibrate_timings': false,
          'vibrate_timings': ['0s', '0.4s', '0.2s', '0.4s'],
        },
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd7_channel_immutability',
    group: 'D — Channels and importance',
    title: 'Changing an existing channel — Android will ignore it',
    description:
        'Re-create chat_v1 with a different importance and watch Android ignore '
        'the change completely. This is the demonstration of why channels carry '
        'a version in their id.',
    expectation:
        'The importance shown on the channel screen stays at its original '
        'value. The only fix is a new channel — chat_v2 — which is what d8 uses.',
    payloadTemplate: {
      'notification': {'title': 'chat_v1', 'body': 'Importance is frozen.'},
      'android': {
        'notification': {'channel_id': 'chat_v1'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd8_channel_group',
    group: 'D — Channels and importance',
    title: 'Channels collected into a group',
    description:
        'Watch the system notification settings: the channels should appear '
        'nested under a named group rather than as a flat list.',
    payloadTemplate: {
      'notification': {'title': 'chat_v2', 'body': 'Grouped in settings.'},
      'android': {
        'notification': {'channel_id': 'chat_v2'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
];
