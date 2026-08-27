import 'package:fcm_app/pages/inbox/widgets/message_tile.dart';
import 'package:fcm_app/pages/sandbox/widgets/send_result_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'app_harness.dart';
import 'expected_events.dart';
import 'telemetry_probe.dart';

/// The widest bound on the send-result card settling into its failure state.
///
/// A ceiling, not a target: `tap()`'s own settle already covers most of the HTTP
/// round trip, so this guards the odd slow frame left over.
const _rejectionSettle = Duration(seconds: 5);

/// How long between checks while [_rejectedCard] waits for the failure card.
///
/// Short, unlike `telemetry_probe.dart`'s `_pollInterval`: that waits on the API and
/// a device, this only on a frame that should already have happened.
const _rejectionPollInterval = Duration(milliseconds: 200);

/// The widest bound on a delivered send's round trip and the frame that renders
/// the trace text.
///
/// Named rather than left to Patrol's default, like every wait in this file.
const _sendRoundTripTimeout = Duration(seconds: 30);

/// How many scroll gestures `scrollTo()` may take, over Patrol's default of 15.
///
/// Group K's header is eleventh of eleven with the first group expanded, which
/// needs more drags than the default budgets for.
const _scenarioScrollMax = 30;

/// Sends [scenario] the way a user would, then asserts what the pipeline recorded.
///
/// Only ever called for a scenario `skipReasonFor` cleared, so it does not re-check.
Future<void> driveScenario(PatrolIntegrationTester $, Scenario scenario) async {
  final expectation = scenarioExpectations[scenario.id]!;

  await launchApp($);
  await _applyScenario($, scenario);
  // Before tapping Send, not after: it must predate the `send_failed` this send
  // will produce, not merely the read of it.
  final sentAt = $.tester.binding.clock.now().toUtc();
  await $(Icons.send_outlined).tap();

  final Finder card = expectation.sendRejected
      ? await _rejectedCard($, scenario, sentAt)
      : cardForTrace(await _readTraceId($));

  await openTelemetry($);
  final arrived = await awaitArrival(
    $,
    card: card,
    expected: expectation.events,
    timeout: expectation.timeout,
  );

  _assertRecorded(scenario, expectation, arrived);
  if (!expectation.sendRejected) {
    await _assertInInbox($);
  }
}

/// Picks [scenario] out of the gallery, handing off to the Sandbox with the
/// template applied.
///
/// By key, not by title, so a gallery change breaks one place and not
/// thirty-six.
Future<void> _applyScenario(
  PatrolIntegrationTester $,
  Scenario scenario,
) async {
  await $(find.byTooltip('Open navigation menu')).tap();
  await $('Scenarios').tap();
  await _expandGroup($, scenario);

  final card = $(Key('scenario-${scenario.id}'));
  await card.scrollTo(maxScrolls: _scenarioScrollMax);
  await card.tap();
}

/// Opens [scenario]'s group unless it is the one the gallery arrives on.
///
/// Which groups are open is known rather than probed: the first is expanded and no
/// other, and every test launches fresh. It has to be known — `ExpansionTile` keeps
/// collapsed children behind an `Offstage`, so their existence proves nothing, and
/// tapping the open group would close it.
///
/// Found by key rather than the tile's text, which is localized prose.
Future<void> _expandGroup(PatrolIntegrationTester $, Scenario scenario) async {
  if (scenario.group == scenarioGallery.first.group) {
    return;
  }

  final title = $(Key('group-${scenario.group}'));
  await title.scrollTo(maxScrolls: _scenarioScrollMax);
  await title.tap();
}

/// The trace id the send reported, read off `SendResultCard`.
///
/// Checks for a refusal first. A delivered scenario can still be rejected for
/// reasons unrelated to it — bad credentials, `SENDER_ID_MISMATCH`, a stale token,
/// a transient 502 — and then the failure branch renders instead of the trace text.
/// Without this check the test dies at Patrol's default timeout with no screenshot,
/// while FCM's own error message sits on screen the whole time. This is the most
/// likely way a first run fails.
Future<String> _readTraceId(PatrolIntegrationTester $) async {
  final failureCard = find.descendant(
    of: find.byType(SendResultCard),
    matching: find.byType(ColoredBox),
  );
  if (failureCard.evaluate().isNotEmpty) {
    final message = $(
      find.descendant(of: failureCard, matching: find.byType(Text)),
    ).text;
    fail('Send was refused instead of delivered: $message');
  }

  final result = $(RegExp(r'trace \S+'));
  await result.waitUntilVisible(timeout: _sendRoundTripTimeout);
  final match = RegExp(r'trace (\S+)').firstMatch(result.text!);

  return match!.group(1)!;
}

/// Checks that the send was refused on screen, and hands back the card.
///
/// The `SandboxFailed` branch draws a `ColoredBox` no other branch does, so there is
/// something to wait for rather than a fixed sleep. The wording is deliberately not
/// pinned — it is FCM's text through two layers of mapping, and a Google copy edit
/// should not fail this. What is pinned is that the card is there, which is what
/// would silently invert if the API began swallowing errors.
Future<Finder> _rejectedCard(
  PatrolIntegrationTester $,
  Scenario scenario,
  DateTime sentAt,
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

  // Claims only what was observed — a failure card within the window, not that
  // the send succeeded. A slow or hung request lands here too.
  expect(
    failureCard.evaluate().isNotEmpty,
    isTrue,
    reason:
        '${scenario.id} was expected to be refused, but no refusal was '
        'observed within $_rejectionSettle',
  );

  return newestRejectedCard(notBefore: sentAt, scenarioId: scenario.id);
}

/// Confirms the other half of the oracle: the Inbox must show the message.
///
/// The Telemetry assertions cover the trace only. `displayed` implies the inbox
/// holds it for most scenarios, but `a2_data_only`, `a4_no_display` and
/// `i2_silent_data_sync` are precisely the three the catalogue tells you to watch
/// in the Inbox rather than the tray.
///
/// Never called for a refused send — nothing reached a device.
Future<void> _assertInInbox(PatrolIntegrationTester $) async {
  await $(find.byTooltip('Open navigation menu')).tap();
  await $('Inbox').tap();

  expect(
    find.byType(MessageTile).evaluate(),
    isNotEmpty,
    reason:
        'the Inbox should hold the delivered message, but the list is empty',
  );
}

/// Compares what arrived against what the table expects, both ways.
void _assertRecorded(
  Scenario scenario,
  ScenarioExpectation expectation,
  Set<TelemetryEventType> arrived,
) {
  final names = arrived.map((type) => type.wireName).join(', ');
  // Set differences rather than one expect per type: the first run is a
  // calibration pass, and "expected displayed, arrived queued, sent, received_fg"
  // is the sentence that makes it useful.
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
