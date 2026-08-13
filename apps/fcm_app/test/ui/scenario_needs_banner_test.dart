import 'package:fcm_app/ui/scenario_needs_banner.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Scenario? scenario) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScenarioNeedsBanner(scenario: scenario)),
        ),
      );

  Scenario scenario(String id) =>
      scenarioGallery.firstWhere((scenario) => scenario.id == id);

  testWidgets('renders nothing when no scenario is loaded', (tester) async {
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
    // `findsNothing` on its own would also hold for a wordless but visible
    // decoration — an empty `Card`, a `Padding` — which is the thing that must
    // not appear. Scaffold lays its body out loosely, so a zero size is proof
    // the banner took no vertical space at all.
    expect(tester.getSize(find.byType(ScenarioNeedsBanner)), Size.zero);
  });

  testWidgets('renders nothing for a scenario that works', (tester) async {
    // The common case: 21 of 66 have no needs, and a banner on each would be
    // noise that trains the user to ignore it.
    await pump(tester, scenario('a1_notification_only'));

    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(ScenarioNeedsBanner)), Size.zero);
  });

  testWidgets('names every unmet need, using its own words', (tester) async {
    await pump(tester, scenario('f8_full_screen_intent'));

    expect(find.textContaining('notification actions'), findsOne);
    expect(find.textContaining('external approval'), findsOne);
    // Both labels differ from their enum names (`interaction`,
    // `externalApproval`), so the two finders above already rule out a banner
    // that printed `need.name`. This pins the rest: that both needs land in one
    // sentence, comma-separated, in declaration order.
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
