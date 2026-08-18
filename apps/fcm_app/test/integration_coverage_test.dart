import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/expected_events.dart';

void main() {
  group('integration coverage', () {
    test('every scenario either has an expectation or a reason to skip', () {
      // The guard that one-file-per-group costs and this buys back: add a scenario
      // to the catalogue and this fails until the suite accounts for it.
      final unaccounted = [
        for (final scenario in scenarioGallery)
          if (skipReasonFor(scenario) == null &&
              !scenarioExpectations.containsKey(scenario.id))
            scenario.id,
      ];

      expect(unaccounted, isEmpty);
    });

    test('the table holds no id the catalogue has dropped', () {
      final ids = {for (final scenario in scenarioGallery) scenario.id};

      expect(
        scenarioExpectations.keys.where((id) => !ids.contains(id)),
        isEmpty,
      );
    });

    test('runs seventeen scenarios and skips forty-nine of sixty-six', () {
      final running = scenarioGallery.where((s) => skipReasonFor(s) == null);

      // Pinned to literals because the split is a claim the spec makes, and drift
      // in either direction is what is worth catching: a scenario becoming
      // unblocked should show up here rather than be absorbed silently.
      expect(scenarioGallery, hasLength(66));
      expect(running, hasLength(17));
      expect(scenarioGallery.length - running.length, 49);
    });

    test('a blocked scenario is skipped for its own need, named in words', () {
      final blocked = scenarioGallery.firstWhere(
        (s) => s.needs.contains(ScenarioNeed.channels),
      );

      // The reason comes from ScenarioNeed.label, so it reads as prose rather than
      // as an enum name a reader has to decode.
      expect(skipReasonFor(blocked), contains('notification channels'));
    });

    test('an iOS-only scenario is skipped, naming the platform', () {
      final ios = scenarioGallery.firstWhere((s) => s.id == 'g4_badge_ios');

      expect(ios.needs, isEmpty);
      expect(skipReasonFor(ios), contains('iOS'));
    });

    test(
      'b3_killed is skipped for the app-kill limitation, not for a need',
      () {
        final killed = scenarioGallery.firstWhere((s) => s.id == 'b3_killed');

        // It carries no needs — delayed sending unblocked it — so if this ever
        // reported a need, the skip policy would be reading the wrong field.
        expect(killed.needs, isEmpty);
        expect(skipReasonFor(killed), contains('killed'));
      },
    );

    test('every expectation names the send-side pair', () {
      // A send always records queued, and then either sent or send_failed. An
      // expectation missing those asserts less than the pipeline guarantees,
      // whatever else it claims about delivery.
      for (final entry in scenarioExpectations.entries) {
        expect(
          entry.value.events,
          contains(TelemetryEventType.queued),
          reason: entry.key,
        );
        expect(
          entry.value.events.contains(TelemetryEventType.sent) ||
              entry.value.events.contains(TelemetryEventType.sendFailed),
          isTrue,
          reason: entry.key,
        );
      }
    });

    test('no expectation both requires and forbids the same event', () {
      for (final entry in scenarioExpectations.entries) {
        expect(
          entry.value.events.intersection(entry.value.absentEvents),
          isEmpty,
          reason: entry.key,
        );
      }
    });

    test('a rejected send expects nothing device-side', () {
      final rejected = scenarioExpectations.entries.where(
        (entry) => entry.value.sendRejected,
      );

      expect(rejected, hasLength(2));
      for (final entry in rejected) {
        expect(
          entry.value.events,
          contains(TelemetryEventType.sendFailed),
          reason: entry.key,
        );
        expect(
          entry.value.absentEvents,
          contains(TelemetryEventType.receivedFg),
          reason: entry.key,
        );
      }
    });
  });
}
