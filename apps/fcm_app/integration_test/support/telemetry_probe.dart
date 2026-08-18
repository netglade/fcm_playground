import 'package:fcm_app/pages/telemetry/widgets/event_row.dart';
import 'package:fcm_app/pages/telemetry/widgets/trace_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// How long to leave between reloads while waiting for delivery.
const _pollInterval = Duration(seconds: 2);

/// Opens the Telemetry destination from the shell's drawer.
///
/// Called once per test. The poll loop below reloads in place rather than navigating
/// again, because a fresh visit rebuilds the page's cubit and would discard the list
/// mid-wait.
Future<void> openTelemetry(PatrolIntegrationTester $) async {
  await $(find.byTooltip('Open navigation menu')).tap();
  await $('Telemetry').tap();
}

/// The card for [traceId], matched on the widget's own field rather than on its text.
///
/// The id is rendered in a monospace `Text`, so a text finder would work — but it
/// would also match the same id anywhere else on the page, and the field cannot lie.
Finder cardForTrace(String traceId) => find.byWidgetPredicate(
  (widget) => widget is TraceCard && widget.timeline.traceId == traceId,
  description: 'TraceCard for trace $traceId',
);

/// The newest trace whose send was refused *by the send this test just made*.
///
/// For a refused send there is no trace id on screen to match — `SendResultCard`
/// shows the server's error and nothing else — so the newest *rejected* trace is
/// the handle, not simply the newest trace. Those are not the same thing, for two
/// distinct reasons, and scoping to `send_failed` alone only rules out the first:
///
/// 1. **Displacement.** `GET /events` orders traces by wherever their newest event
///    landed, so a trace already on screen moves back to the front the moment it
///    gains one — including a `received_fg` or `displayed` from an earlier
///    scenario's delivery arriving late. `c2_priority_normal` carries a two-minute
///    timeout precisely because FCM is entitled to hold a normal-priority push
///    that long, so a delivery from group C can still land while group K is
///    running. No delivered scenario ever records `send_failed`, so a late
///    delivery can never push its way in front of a rejected trace here.
/// 2. **Staleness.** The telemetry SQLite file persists across runs by design, so
///    without [notBefore] the newest card carrying `send_failed` could be *this
///    scenario's own trace from a previous run*, or the other rejected scenario's
///    trace from minutes earlier — if the send under test fails for an unrelated
///    reason (a dropped `adb reverse`, a timed-out `POST /send`) and produces no
///    `send_failed` of its own, the stale card still satisfies every assertion.
///    [notBefore] closes that gap: only a `send_failed` recorded at or after the
///    instant this test tapped Send can match. [scenarioId] narrows further, for
///    the case where two rejections land in the same instant — `SandboxCubit.send`
///    always sets it from `state.selectedScenario?.id`, so it is safe to pass
///    whenever the caller knows it.
///
/// Matched on `timeline.eventOf` and `timeline.scenarioId`, the same underlying
/// data `EventRow` reads, rather than on rendered text, for the reason
/// [cardForTrace] gives.
Finder newestRejectedCard({required DateTime notBefore, String? scenarioId}) =>
    find.byWidgetPredicate(
      (widget) {
        if (widget is! TraceCard) {
          return false;
        }
        final failure = widget.timeline.eventOf(TelemetryEventType.sendFailed);
        if (failure == null || failure.at.isBefore(notBefore)) {
          return false;
        }

        return scenarioId == null || widget.timeline.scenarioId == scenarioId;
      },
      description: 'newest TraceCard with a send_failed at or after $notBefore',
    ).first;

/// Whether [card] shows an arrived (non-null) event of [type].
///
/// Read off `EventRow.event` rather than off the row's text: the row draws an em dash
/// for an absence, and matching a dash would be matching a rendering decision. Kept as
/// its own function, rather than inlined into [arrivedTypes], so the collection-`for`
/// it is called from does not itself carry the widget-predicate closure.
bool _hasArrived(Finder card, TelemetryEventType type) => find
    .descendant(
      of: card,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is EventRow && widget.type == type && widget.event != null,
      ),
    )
    .evaluate()
    .isNotEmpty;

/// Which event types [card] shows as arrived.
Set<TelemetryEventType> arrivedTypes(Finder card) => {
  for (final type in TelemetryEventType.values)
    if (_hasArrived(card, type)) type,
};

/// Reloads until every type in [expected] has arrived on [card], or [timeout] passes.
///
/// Returns whatever had arrived when it stopped — including on timeout, so the caller
/// can report the difference instead of a bare "timed out". Polling rather than one
/// read: `queued` and `sent` are on the server the moment Send returns, but
/// `received_fg` and `displayed` travel back from the device afterwards.
Future<Set<TelemetryEventType>> awaitArrival(
  PatrolIntegrationTester $, {
  required Finder card,
  required Set<TelemetryEventType> expected,
  required Duration timeout,
}) async {
  // `binding.clock` rather than `DateTime.now()`: the binding is the only thing that
  // knows whether time is real here. Patrol runs under
  // `IntegrationTestWidgetsFlutterBinding`, whose clock is the real one, so both agree
  // today — but a plan that reached past the binding would be right by luck.
  final deadline = $.tester.binding.clock.now().add(timeout);
  while (true) {
    await $(find.byTooltip('Reload')).tap();
    final found = card.evaluate().isNotEmpty;
    final arrived = found ? arrivedTypes(card) : <TelemetryEventType>{};
    if (expected.difference(arrived).isEmpty ||
        $.tester.binding.clock.now().isAfter(deadline)) {
      // Told apart on purpose: "never found" and "found with these rows empty"
      // are different diagnoses. `EventsTab` is a `ListView` that builds only the
      // topmost few cards and nothing here scrolls it, so a trace pushed out of
      // the built range would otherwise read as nothing having been recorded —
      // even though the caller demonstrably read a trace id off a successful
      // send moments earlier.
      if (!found) {
        fail(
          'The TraceCard never appeared in the Events list within $timeout. '
          'It may have been pushed out of the built range by a later trace — '
          'scroll is not applied here — or the id it was matched on is wrong.',
        );
      }

      return arrived;
    }
    // A real delay, then one frame. `$.pump(duration)` would be the shorter spelling,
    // but the wait here is for the API and the device rather than for animation.
    await Future<void>.delayed(_pollInterval);
    await $.pump();
  }
}
