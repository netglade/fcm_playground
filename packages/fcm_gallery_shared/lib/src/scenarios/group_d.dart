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
    l10nKey: 'd1_importance_high',
    group: 'D',
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
    l10nKey: 'd2_importance_default',
    group: 'D',
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
    l10nKey: 'd3_importance_low',
    group: 'D',
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
    l10nKey: 'd4_importance_min',
    group: 'D',
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
    l10nKey: 'd5_custom_sound',
    group: 'D',
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
    l10nKey: 'd6_vibration_pattern',
    group: 'D',
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
    l10nKey: 'd7_channel_immutability',
    group: 'D',
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
    l10nKey: 'd8_channel_group',
    group: 'D',
    payloadTemplate: {
      'notification': {'title': 'chat_v2', 'body': 'Grouped in settings.'},
      'android': {
        'notification': {'channel_id': 'chat_v2'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
];
