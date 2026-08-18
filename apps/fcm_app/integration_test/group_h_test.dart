import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:patrol/patrol.dart';

import 'support/expected_events.dart';
import 'support/scenario_drive.dart';

void main() {
  for (final scenario in groupH) {
    final skipReason = skipReasonFor(scenario);
    // The reason rides in the description because Patrol's `skip` is `bool?`, not
    // the `String?` the `test` package takes — passed there it would never print.
    patrolTest(
      skipReason == null ? scenario.id : '${scenario.id} — SKIP: $skipReason',
      ($) => driveScenario($, scenario),
      skip: skipReason != null,
    );
  }
}
