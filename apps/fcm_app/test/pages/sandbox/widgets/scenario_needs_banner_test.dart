import 'package:fcm_app/pages/sandbox/widgets/scenario_needs_banner.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, Scenario? scenario) =>
      pumpApp(tester, ScenarioNeedsBanner(scenario: scenario));

  Scenario scenario(String id) =>
      scenarioGallery.firstWhere((scenario) => scenario.id == id);

  testWidgets('renders nothing when no scenario is loaded', (tester) async {
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
    // `findsNothing` alone would hold for a wordless but visible decoration. Scaffold
    // lays its body out loosely, so a zero size proves the banner took no space.
    expect(tester.getSize(find.byType(ScenarioNeedsBanner)), Size.zero);
  });

  testWidgets('renders nothing for a scenario that works', (tester) async {
    // The common case, and a banner on each would train the user to ignore it.
    await pump(tester, scenario('a1_notification_only'));

    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(ScenarioNeedsBanner)), Size.zero);
  });

  testWidgets('names every unmet need, using its own words', (tester) async {
    await pump(tester, scenario('f8_full_screen_intent'));

    expect(find.textContaining('notification actions'), findsOne);
    expect(find.textContaining('external approval'), findsOne);
    // Both labels differ from their enum names, so the finders above already rule out
    // a banner printing `need.name`. This pins the rest: one sentence,
    // comma-separated, in declaration order.
    expect(
      find.text(
        'Needs notification actions, external approval. The push will still be '
        'sent, but this scenario cannot be observed yet.',
      ),
      findsOne,
    );
  });

  testWidgets('says the push is still sent, so the banner is not a block', (
    tester,
  ) async {
    final single = scenario('d1_importance_high');
    // Guards the assertion below against a scenario that quietly lost its
    // needs: the copy could then only be missing, never wrong.
    expect(single.needs, [ScenarioNeed.channels]);

    await pump(tester, single);

    expect(find.textContaining('still be sent'), findsOne);
    expect(find.textContaining('notification channels'), findsOne);
  });
}
