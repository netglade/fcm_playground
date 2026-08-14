import '../send_target.dart';
import 'scenario.dart';
import 'scenario_need.dart';

/// **K — Edge cases and errors.** The failures worth being able to reproduce.
///
/// Two of these are payload-level and work today: an oversize body and a dead
/// token both produce a clean, specific error from FCM, and being able to trigger
/// them on demand is what makes the error handling elsewhere trustworthy. The
/// other three are states of the device that no payload can create.
const groupK = <Scenario>[
  Scenario(
    id: 'k1_payload_oversize',
    group: 'K — Edge cases and errors',
    title: 'A payload over FCM\'s 4 KB limit',
    description:
        'Watch that the API surfaces FCM\'s error with a usable message rather '
        'than a bare 400.',
    expectation:
        'FCM rejects this with INVALID_ARGUMENT. The send should fail before '
        'anything reaches the device.',
    payloadTemplate: {
      'data': {
        'chunk_1':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
            'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
            'ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
            'aliquip ex ea commodo consequat. Duis aute irure dolor in '
            'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
            'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in '
            'culpa qui officia deserunt mollit anim id est laborum. Sed ut '
            'perspiciatis unde omnis iste natus error sit voluptatem accusantium '
            'doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo '
            'inventore veritatis et quasi architecto beatae vitae dicta sunt '
            'explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur '
            'aut odit aut fugit, sed quia consequuntur magni dolores eos qui '
            'ratione voluptatem sequi nesciunt.',
        'chunk_2':
            'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, '
            'consectetur, adipisci velit, sed quia non numquam eius modi tempora '
            'incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut '
            'enim ad minima veniam, quis nostrum exercitationem ullam corporis '
            'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? '
            'Quis autem vel eum iure reprehenderit qui in ea voluptate velit '
            'esse quam nihil molestiae consequatur, vel illum qui dolorem eum '
            'fugiat quo voluptas nulla pariatur? At vero eos et accusamus et '
            'iusto odio dignissimos ducimus qui blanditiis praesentium '
            'voluptatum deleniti atque corrupti quos dolores et quas molestias '
            'excepturi sint occaecati cupiditate non provident, similique sunt '
            'in culpa qui officia deserunt mollitia animi, id est laborum et '
            'dolorum fuga.',
        'chunk_3':
            'Et harum quidem rerum facilis est et expedita distinctio. Nam '
            'libero tempore, cum soluta nobis est eligendi optio cumque nihil '
            'impedit quo minus id quod maxime placeat facere possimus, omnis '
            'voluptas assumenda est, omnis dolor repellendus. Temporibus autem '
            'quibusdam et aut officiis debitis aut rerum necessitatibus saepe '
            'eveniet ut et voluptates repudiandae sint et molestiae non '
            'recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut '
            'aut reiciendis voluptatibus maiores alias consequatur aut '
            'perferendis doloribus asperiores repellat. Sed ut perspiciatis unde '
            'omnis iste natus error sit voluptatem accusantium doloremque '
            'laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore '
            'veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
        'chunk_4':
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua, '
            'ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
            'nisi ut aliquip ex ea commodo consequat, duis aute irure dolor in '
            'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
            'pariatur, excepteur sint occaecat cupidatat non proident, sunt in '
            'culpa qui officia deserunt mollit anim id est laborum, and that '
            'should be comfortably past four kilobytes once the other chunks are '
            'counted alongside it.',
        // Chunks 5 and 6 are here because four were not enough: keys and values
        // together came to 2885 characters, well inside the limit this scenario
        // exists to break. The group test measures the size rather than trusting
        // the name, which is what caught it. Do not trim any of the six.
        'chunk_5':
            'At vero eos et accusamus et iusto odio dignissimos ducimus qui '
            'blanditiis praesentium voluptatum deleniti atque corrupti quos '
            'dolores et quas molestias excepturi sint occaecati cupiditate non '
            'provident, similique sunt in culpa qui officia deserunt mollitia '
            'animi, id est laborum et dolorum fuga. Et harum quidem rerum '
            'facilis est et expedita distinctio. Nam libero tempore, cum soluta '
            'nobis est eligendi optio cumque nihil impedit quo minus id quod '
            'maxime placeat facere possimus, omnis voluptas assumenda est, omnis '
            'dolor repellendus. Quis autem vel eum iure reprehenderit qui in ea '
            'voluptate velit esse quam nihil molestiae consequatur, vel illum '
            'qui dolorem eum fugiat quo voluptas nulla pariatur.',
        'chunk_6':
            'Temporibus autem quibusdam et aut officiis debitis aut rerum '
            'necessitatibus saepe eveniet ut et voluptates repudiandae sint et '
            'molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente '
            'delectus, ut aut reiciendis voluptatibus maiores alias consequatur '
            'aut perferendis doloribus asperiores repellat. Nemo enim ipsam '
            'voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed '
            'quia consequuntur magni dolores eos qui ratione voluptatem sequi '
            'nesciunt, neque porro quisquam est qui dolorem ipsum quia dolor '
            'sit amet consectetur adipisci velit. Sed quia non numquam eius modi '
            'tempora incidunt ut labore et dolore magnam aliquam quaerat '
            'voluptatem, ut enim ad minima veniam quis nostrum exercitationem '
            'ullam corporis suscipit laboriosam nisi ut aliquid ex ea commodi '
            'consequatur. Duis aute irure dolor in reprehenderit in voluptate '
            'velit esse cillum dolore eu fugiat nulla pariatur, and this last '
            'stretch exists purely so that the payload clears four kilobytes by '
            'a margin no reading of the limit can argue with.',
      },
    },
  ),
  Scenario(
    id: 'k2_invalid_token',
    group: 'K — Edge cases and errors',
    title: 'A token that is no longer registered',
    description:
        'The everyday production failure. Watch that the API reports it as '
        'UNREGISTERED rather than a generic 404, which is what tells a real '
        'backend to delete the row.',
    expectation:
        'FCM answers with UNREGISTERED, which this API maps to 404 with its own '
        'wording. The errorCode in error.details takes precedence over the '
        'top-level NOT_FOUND status.',
    payloadTemplate: {
      'notification': {'title': 'Nobody', 'body': 'This token is dead.'},
    },
    target: TokenTarget(
      'fZ9-this-token-was-never-real-and-never-will-be-000000000000',
    ),
  ),
  Scenario(
    id: 'k3_permission_denied',
    group: 'K — Edge cases and errors',
    title: 'POST_NOTIFICATIONS denied on Android 13+',
    description:
        'Watch that the data handler still runs and the inbox still fills, even '
        'though nothing can be drawn.',
    payloadTemplate: {
      'notification': {'title': 'Denied', 'body': 'Nothing should be drawn.'},
      'data': {'event': 'permission_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell pm revoke cz.netglade.fcm_app '
        'android.permission.POST_NOTIFICATIONS — then send, and check the Inbox '
        'page rather than the tray.',
  ),
  Scenario(
    id: 'k4_notifications_disabled',
    group: 'K — Edge cases and errors',
    title: 'Notifications switched off in system settings',
    description:
        'Distinct from a denied permission: the app has the grant and the user '
        'has turned it off. Watch that data delivery is unaffected.',
    payloadTemplate: {
      'notification': {'title': 'Disabled', 'body': 'Tray is off.'},
      'data': {'event': 'disabled_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Notifications › off. Send, then confirm '
        'the row appears in the Inbox page.',
  ),
  Scenario(
    id: 'k5_battery_restricted',
    group: 'K — Edge cases and errors',
    title: 'App in Restricted battery mode',
    description:
        'The state a user reaches by tapping "restrict" in battery settings. '
        'Watch whether a HIGH priority push still wakes the app.',
    payloadTemplate: {
      'notification': {'title': 'Restricted', 'body': 'Battery probe.'},
      'android': {'priority': 'HIGH'},
      'data': {'event': 'battery_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Battery › Restricted. Send and compare '
        'the delay against c1_priority_high in the unrestricted state.',
  ),
];
