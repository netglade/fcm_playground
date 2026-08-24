import 'scenario.dart';

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
    group: 'A — Basic delivery',
    title: 'Notification-only payload',
    description:
        'Watch which layer drew it — the system while backgrounded, the app '
        'while foregrounded — and how the icon and accent colour come out.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
    },
  ),
  Scenario(
    id: 'a2_data_only',
    group: 'A — Basic delivery',
    title: 'Data-only payload, drawn locally',
    description:
        'Nothing draws this but the app. Watch whether it arrives at all with '
        'the app killed, which is the case data-only delivery exists for.',
    expectation:
        'On iOS a data-only push needs content-available and is throttled; see '
        'i3_ios_content_available.',
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
    group: 'A — Basic delivery',
    title: 'notification and data together',
    description:
        'The common shape in production. Watch whether the data map reaches the '
        'handler after a tap, which is where deep links get their arguments.',
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
    group: 'A — Basic delivery',
    title: 'Data logged silently, drawn blank',
    description:
        'A silent synchronisation: the handler runs and writes a log line. '
        'Nothing suppresses a titleless banner, so a tray entry still appears — '
        'icon and app name, no text. The observable difference from a1 is the '
        'missing text, not a missing notification. Watch the inbox for the log '
        'line; the tray has nothing to read.',
    payloadTemplate: {
      'data': {'event': 'log_only', 'silent': 'true'},
    },
  ),
];
