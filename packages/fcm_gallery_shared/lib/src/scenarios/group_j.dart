import 'package:fcm_gallery_shared/src/scenarios/scenario.dart';
import 'package:fcm_gallery_shared/src/scenarios/scenario_need.dart';
import 'package:fcm_gallery_shared/src/send_target.dart';

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
    l10nKey: 'j1_topic',
    group: 'J',
    payloadTemplate: {
      'notification': {'title': 'Topic push', 'body': 'Sent to "news".'},
    },
    target: TopicTarget('news'),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j2_condition',
    l10nKey: 'j2_condition',
    group: 'J',
    payloadTemplate: {
      'notification': {'title': 'Condition push', 'body': 'news AND beta.'},
    },
    target: ConditionTarget("'news' in topics && 'beta' in topics"),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j3_multicast',
    l10nKey: 'j3_multicast',
    group: 'J',
    payloadTemplate: {
      'notification': {'title': 'Everyone', 'body': 'Compare across devices.'},
      'android': {'priority': 'HIGH'},
    },
    target: AllDevicesTarget(),
    needs: [ScenarioNeed.targeting],
  ),
];
