import 'package:fcm_app/pages/sandbox/widgets/send_result_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'app_harness.dart';
import 'expected_events.dart';
import 'telemetry_probe.dart';

/// The widest bound given to the send-result card settling into its failure
/// state before [_rejectedCard] gives up waiting for it.
///
/// A ceiling, not a target: `tap()`'s own settle already gives the send's HTTP
/// round trip most of its room to finish, so this only guards the odd slow frame
/// left over.
const _rejectionSettle = Duration(seconds: 5);

/// How long to leave between checks while [_rejectedCard] waits for the failure
/// card to render.
///
/// Short, unlike `telemetry_probe.dart`'s `_pollInterval`: that one waits on the API
/// and a device, this one only waits on the frame after a state change that, per
/// `tap()`'s own settle, should already have happened by the time this loop starts.
const _rejectionPollInterval = Duration(milliseconds: 200);

/// Sends [scenario] the way a user would, then asserts what the pipeline recorded.
///
/// Only ever called for a scenario `skipReasonFor` cleared, so it does not re-check.
Future<void> driveScenario(PatrolIntegrationTester $, Scenario scenario) async {
  final expectation = scenarioExpectations[scenario.id]!;

  await launchApp($);
  await _applyScenario($, scenario);
  await $(Icons.send_outlined).tap();

  final Finder card = expectation.sendRejected
      ? await _rejectedCard($, scenario)
      : cardForTrace(await _readTraceId($));

  await openTelemetry($);
  final arrived = await awaitArrival(
    $,
    card: card,
    expected: expectation.events,
    timeout: expectation.timeout,
  );

  _assertRecorded(scenario, expectation, arrived);
}

/// Picks [scenario] out of the gallery, which hands off to the Sandbox with the
/// template already applied.
///
/// Taps the card by key rather than by title: one place breaks when the gallery
/// changes, not seventeen.
Future<void> _applyScenario(
  PatrolIntegrationTester $,
  Scenario scenario,
) async {
  await $(find.byTooltip('Open navigation menu')).tap();
  await $('Scenarios').tap();
  await _expandGroup($, scenario);

  final card = $(Key('scenario-${scenario.id}'));
  await card.scrollTo();
  await card.tap();
}

/// Opens [scenario]'s group unless it is the one the gallery arrives on.
///
/// `ScenarioGroupList` expands the first group and no other, and every test launches a
/// fresh app, so which groups are open is known rather than probed. It has to be:
/// `ExpansionTile` keeps collapsed children in the tree behind an `Offstage`, so their
/// mere existence proves nothing — and tapping the already-open group would close it.
Future<void> _expandGroup(PatrolIntegrationTester $, Scenario scenario) async {
  if (scenario.group == scenarioGallery.first.group) {
    return;
  }

  final title = $(scenario.group);
  await title.scrollTo();
  await title.tap();
}

/// The trace id the send reported, read off `SendResultCard`.
Future<String> _readTraceId(PatrolIntegrationTester $) async {
  final result = $(RegExp(r'trace \S+'));
  await result.waitUntilVisible();
  final match = RegExp(r'trace (\S+)').firstMatch(result.text!);

  return match!.group(1)!;
}

/// Checks that the send was refused on screen, and hands back the card to inspect.
///
/// A refusal renders `SendResultCard`'s `SandboxFailed` branch, which draws a
/// `ColoredBox` no other branch of that switch does — so there is something to wait
/// for after all, rather than a fixed sleep with nothing behind it. The wording inside
/// is deliberately not pinned: it is FCM's own error text travelling through two
/// layers of mapping, and asserting it here would make the test fail on a Google copy
/// edit. What is pinned is that the failure card is absent, which is the part that
/// would silently invert if the API started swallowing errors.
Future<Finder> _rejectedCard(
  PatrolIntegrationTester $,
  Scenario scenario,
) async {
  final failureCard = find.descendant(
    of: find.byType(SendResultCard),
    matching: find.byType(ColoredBox),
  );
  final deadline = $.tester.binding.clock.now().add(_rejectionSettle);
  while (failureCard.evaluate().isEmpty &&
      $.tester.binding.clock.now().isBefore(deadline)) {
    await Future<void>.delayed(_rejectionPollInterval);
    await $.pump();
  }

  // Claims only what was observed: the absence of a failure card within the
  // window, not that the send succeeded — a slow or hung request lands here too,
  // and the two are worth telling apart in whoever reads the first failing run.
  expect(
    failureCard.evaluate().isNotEmpty,
    isTrue,
    reason:
        '${scenario.id} was expected to be refused, but no refusal was '
        'observed within $_rejectionSettle',
  );

  return newestRejectedCard();
}

/// Compares what arrived against what the table expects, both ways.
void _assertRecorded(
  Scenario scenario,
  ScenarioExpectation expectation,
  Set<TelemetryEventType> arrived,
) {
  final names = arrived.map((type) => type.wireName).join(', ');
  // Reported as set differences rather than one expect per type: the first run of this
  // suite is a calibration pass, and "expected displayed, arrived queued, sent,
  // received_fg" is the sentence that makes it useful.
  expect(
    expectation.events.difference(arrived),
    isEmpty,
    reason: '${scenario.id}: expected but never arrived. Arrived: $names',
  );
  expect(
    expectation.absentEvents.intersection(arrived),
    isEmpty,
    reason: '${scenario.id}: arrived but should not have. Arrived: $names',
  );
}
