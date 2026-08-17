import '../send_target.dart';
import 'scenario.dart';
import 'scenario_need.dart';

/// **J — Targeting.** Who receives it, rather than what it says.
///
/// The audience lives in [Scenario.target] and never in the payload: the typed
/// `FcmMessage` rejects `token`, `topic` and `condition` outright, so a template
/// pasted out of Google's docs cannot quietly broadcast. The API reads the target
/// from the send envelope instead.
///
/// All three are blocked, for two reasons. j1 and j2 can be *sent* today — FCM
/// answers 200 — but nothing is delivered, because this device never called
/// `subscribeToTopic`, and a send that succeeds while nothing arrives is worse than
/// no scenario. j3 needs a registry of tokens this app does not keep.
const groupJ = <Scenario>[
  Scenario(
    id: 'j1_topic',
    group: 'J — Targeting',
    title: 'Send to a topic',
    description:
        'Subscribe the device, then send to the topic rather than the token. '
        'Watch that it arrives without the sender knowing any token at all.',
    expectation:
        'Sending works now and FCM answers 200, but nothing is delivered until '
        'the app can subscribe to a topic.',
    payloadTemplate: {
      'notification': {'title': 'Topic push', 'body': 'Sent to "news".'},
    },
    target: TopicTarget('news'),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j2_condition',
    group: 'J — Targeting',
    title: 'Send to a boolean topic condition',
    description:
        'A device must be in both topics to receive this. Watch that subscribing '
        'to only one excludes it.',
    expectation:
        'Like j1, sending works now and FCM answers 200 — but nothing is '
        'delivered until the app can subscribe to both topics.',
    payloadTemplate: {
      'notification': {'title': 'Condition push', 'body': 'news AND beta.'},
    },
    target: ConditionTarget("'news' in topics && 'beta' in topics"),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j3_multicast',
    group: 'J — Targeting',
    title: 'Send to every registered device',
    description:
        'The main tool for comparing behaviour across handsets: one send, every '
        'device, and the differences are the result.',
    expectation:
        'FCM has no "all devices" audience, so this needs a token registry the '
        'API does not have. Sending it now returns 501 with that reason rather '
        'than quietly delivering to one device.',
    payloadTemplate: {
      'notification': {'title': 'Everyone', 'body': 'Compare across devices.'},
      'android': {'priority': 'HIGH'},
    },
    target: AllDevicesTarget(),
    needs: [ScenarioNeed.targeting],
  ),
];
