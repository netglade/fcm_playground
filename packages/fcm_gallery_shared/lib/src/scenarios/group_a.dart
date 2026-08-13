import 'scenario.dart';

/// **A — Basic delivery.** The four shapes an FCM message can take, and which
/// layer draws each one.
///
/// The whole catalogue rests on telling these apart: a `notification` payload is
/// drawn by the system while the app is backgrounded and by the app itself while
/// it is foregrounded, and a `data` payload is never drawn by anyone unless the
/// app does it. Most confusion about "the push did not arrive" is really one of
/// these four being mistaken for another.
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
    // Deliberately NOT requiresKilledApp, despite the description asking about
    // the killed case. That flag means "meaningless unless the app is killed",
    // which implies the scenario needs delayed sending to be arranged at all —
    // and a data-only push is observable in every app state, so this one is
    // sendable today. b3_killed is the scenario that is only about the killed
    // state, and it carries the flag and the need together.
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
    title: 'Data with nothing drawn, logged only',
    description:
        'A silent synchronisation: the handler runs and writes a log line, and '
        'the user sees nothing at all. Watch the inbox rather than the tray.',
    payloadTemplate: {
      'data': {'event': 'log_only', 'silent': 'true'},
    },
  ),
];
