import 'package:fcm_app/pages/scenarios/widgets/scenario_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Scenario scenario(String id) => scenarioGallery.firstWhere((s) => s.id == id);

  Future<int> pump(WidgetTester tester, Scenario subject) async {
    var taps = 0;
    await pumpApp(tester, ScenarioCard(scenario: subject, onTap: () => taps++));

    return taps;
  }

  testWidgets('gives each scenario its own card, so rows do not run together', (
    tester,
  ) async {
    await pump(tester, scenario('a1_notification_only'));

    // findsOne, not findsAtLeast: one card per scenario is the point. A nested
    // Card would still separate them visually but would double every border.
    expect(find.byType(Card), findsOne);
    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(ListTile)),
      findsOne,
    );
  });

  testWidgets('shows the id, which is how every other surface names it', (
    tester,
  ) async {
    // The source catalogue, the validate-only sweep and the tests all name ids.
    await pump(tester, scenario('c7_standby_bucket'));

    expect(find.text('c7_standby_bucket'), findsOne);
    expect(find.text(scenario('c7_standby_bucket').title), findsOne);
  });

  testWidgets('reports the whole card body, not only the title', (
    tester,
  ) async {
    // b5 carries a description AND an expectation, so it exercises the optional
    // caveat line rather than only the always-present ones.
    final subject = scenario('b5_force_stopped');

    await pump(tester, subject);

    expect(find.text(subject.description), findsOne);
    expect(find.text(subject.expectation!), findsOne);
  });

  testWidgets('flags a scenario that cannot be demonstrated yet', (
    tester,
  ) async {
    final blocked = scenario('d1_importance_high');
    expect(blocked.isSupported, isFalse, reason: 'the fixture must be blocked');

    await pump(tester, blocked);

    expect(find.text('needs work'), findsOne);
  });

  testWidgets('leaves a working scenario unflagged', (tester) async {
    final working = scenario('a1_notification_only');
    expect(
      working.isSupported,
      isTrue,
      reason: 'the fixture must be supported',
    );

    await pump(tester, working);

    expect(find.text('needs work'), findsNothing);
  });

  testWidgets('says when a scenario needs the app killed', (tester) async {
    await pump(tester, scenario('b3_killed'));

    expect(find.text('Needs the app killed'), findsOne);
  });

  testWidgets('the whole card is the tap target, not just the title', (
    tester,
  ) async {
    // The description is the largest part of the card, so a title-only tap target
    // would leave most of it dead.
    var taps = 0;
    await pumpApp(
      tester,
      ScenarioCard(scenario: scenario('a3_hybrid'), onTap: () => taps++),
    );

    await tester.tap(find.text(scenario('a3_hybrid').description));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
