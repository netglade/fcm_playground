import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';

/// **A — Basic delivery.** The four shapes an FCM message can take, and which layer
/// draws each one.
///
/// A `notification` payload is drawn by the system while the app is backgrounded and
/// by the app while it is foregrounded; a `data` payload is never drawn by anyone
/// unless the app does it. Most "the push did not arrive" confusion is one of these
/// four mistaken for another.
const groupA = <Scenario>[
  Scenario(
    id: 'a1_notification_only',
    l10nKey: 'a1_notification_only',
    group: 'A',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
    },
  ),
  Scenario(
    id: 'a2_data_only',
    l10nKey: 'a2_data_only',
    group: 'A',
    payloadTemplate: {
      'data': {'event': 'sync', 'build_number': '128'},
    },
    // Deliberately NOT requiresKilledApp: that flag means "meaningless unless the
    // app is killed", and a data-only push is observable in every state, so it does
    // not apply here. It says nothing about needing delayed sending — that is
    // arranged for every scenario without asking.
  ),
  Scenario(
    id: 'a3_hybrid',
    l10nKey: 'a3_hybrid',
    group: 'A',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
      'data': {'event': 'build_finished', 'deep_link': '/builds/128'},
    },
  ),
  Scenario(
    id: 'a4_no_display',
    l10nKey: 'a4_no_display',
    group: 'A',
    payloadTemplate: {
      'data': {'event': 'log_only', 'silent': 'true'},
    },
  ),
];
