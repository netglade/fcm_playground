import 'package:fcm_app/pages/telemetry/widgets/event_row.dart';
import 'package:fcm_app/pages/telemetry/widgets/trace_card.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// How long to leave between reloads while waiting for delivery.
const _pollInterval = Duration(seconds: 2);

/// Opens the Telemetry destination from the shell's drawer.
///
/// Once per test: the poll loop reloads in place, because a fresh visit rebuilds
/// the cubit and would discard the list mid-wait.
Future<void> openTelemetry(PatrolIntegrationTester $) async {
  await $(find.byTooltip('Open navigation menu')).tap();
  await $('Telemetry').tap();
}

/// The card for [traceId], matched on the widget's field rather than its text — a
/// text finder would also match the same id elsewhere on the page.
Finder cardForTrace(String traceId) => find.byWidgetPredicate(
  (widget) => widget is TraceCard && widget.timeline.traceId == traceId,
  description: 'TraceCard for trace $traceId',
);

/// The newest trace whose send was refused *by the send this test just made*.
///
/// A refused send puts no trace id on screen, so the handle is the newest
/// *rejected* trace — which is not simply the newest trace, for two reasons.
///
/// 1. **Displacement.** `GET /events` orders traces by their newest event, so a
///    late delivery from an earlier scenario moves that trace back to the front.
///    Scoping to `send_failed` rules this out: no delivered scenario records one.
/// 2. **Staleness.** The telemetry file persists across runs, so the newest
///    `send_failed` could be this scenario's own trace from a previous run. If the
///    send under test then fails for an unrelated reason and records no
///    `send_failed`, that stale card would satisfy every assertion. [notBefore]
///    closes it; [scenarioId] narrows further for two rejections in one instant.
///
/// Matched on `timeline.eventOf` and `timeline.scenarioId` rather than rendered
/// text, for the reason [cardForTrace] gives.
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
/// Read off `EventRow.event`, not the row's text: an absence draws an em dash, and
/// matching that would be matching a rendering decision.
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

/// Reloads until every type in [expected] has arrived on [card], or [timeout]
/// passes.
///
/// Returns whatever had arrived, including on timeout, so the caller reports the
/// difference rather than a bare "timed out". Polling because `queued` and `sent`
/// are on the server at once, while the arrivals travel back afterwards.
Future<Set<TelemetryEventType>> awaitArrival(
  PatrolIntegrationTester $, {
  required Finder card,
  required Set<TelemetryEventType> expected,
  required Duration timeout,
}) async {
  // `binding.clock`, not `DateTime.now()`: only the binding knows whether time is
  // real here. They agree under Patrol today, but reaching past it would be right
  // by luck.
  final deadline = $.tester.binding.clock.now().add(timeout);
  while (true) {
    await $(find.byTooltip('Reload')).tap();
    final found = card.evaluate().isNotEmpty;
    final arrived = found ? arrivedTypes(card) : <TelemetryEventType>{};
    if (expected.difference(arrived).isEmpty ||
        $.tester.binding.clock.now().isAfter(deadline)) {
      // "Never found" and "found but empty" are different diagnoses.
      // `EventsTab` builds only the topmost cards and nothing scrolls it, so a
      // trace pushed out of range would otherwise read as nothing recorded.
      if (!found) {
        fail(
          'The TraceCard never appeared in the Events list within $timeout. '
          'It may have been pushed out of the built range by a later trace — '
          'scroll is not applied here — or the id it was matched on is wrong.',
        );
      }

      return arrived;
    }
    // A real delay, then one frame: the wait is for the API and the device, not
    // for animation.
    await Future<void>.delayed(_pollInterval);
    await $.pump();
  }
}
