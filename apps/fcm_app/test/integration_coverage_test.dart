import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/expected_events.dart';

/// Which of [skipReasonFor]'s three branches a skipped [scenario] falls under,
/// `'unclassified'` if none of them account for it, or null when it runs.
///
/// Mirrors that function's own order — needs, then platform, then
/// requiresKilledApp — over the same fields it reads, rather than a hard-coded
/// list of ids: a scenario that becomes unblocked drops out of its bucket
/// instead of staying miscounted. The fall-through is a genuine outcome, not
/// a default: if [skipReasonFor] ever grows a fourth reason to skip, the
/// scenario it applies to lands here instead of silently joining `'appKill'`,
/// and the sum assertion below catches it.
String? _skipBucket(Scenario scenario) {
  if (skipReasonFor(scenario) == null) return null;

  if (scenario.needs.isNotEmpty) return 'needs';

  final expectation = scenarioExpectations[scenario.id];
  if (expectation != null && !expectation.platforms.contains(suitePlatform)) {
    return 'ios';
  }

  if (scenario.requiresKilledApp) return 'appKill';

  return 'unclassified';
}

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

    test('runs thirty-two scenarios and skips thirty-four of sixty-six', () {
      final running = scenarioGallery.where((s) => skipReasonFor(s) == null);

      // Pinned to literals because the split is a claim the spec makes, and drift
      // in either direction is what is worth catching: a scenario becoming
      // unblocked should show up here rather than be absorbed silently.
      expect(scenarioGallery, hasLength(66));
      expect(running, hasLength(32));
      expect(scenarioGallery.length - running.length, 34);
    });

    test('a blocked scenario is skipped for its own need, named in words', () {
      final blocked = scenarioGallery.firstWhere(
        (s) => s.needs.contains(ScenarioNeed.styles),
      );

      // The reason comes from ScenarioNeed.name now — a stable enum name rather
      // than a localized label, which is right for a test report but means the
      // word here is the bare enum member, not the prose the UI shows.
      expect(skipReasonFor(blocked), contains('styles'));
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

    test('twenty-eight scenarios are skipped for an unbuilt ScenarioNeed', () {
      final blockedByNeed = scenarioGallery.where(
        (s) => _skipBucket(s) == 'needs',
      );

      expect(blockedByNeed, hasLength(28));
    });

    test('four scenarios are skipped for being iOS-only', () {
      final iosOnly = scenarioGallery.where((s) => _skipBucket(s) == 'ios');

      expect(iosOnly, hasLength(4));
    });

    test('two scenarios are skipped only for needing the app killed', () {
      final appKillOnly = scenarioGallery.where(
        (s) => _skipBucket(s) == 'appKill',
      );

      // f5_deeplink_killed's ScenarioNeed is gone now that the deep-link
      // routing it needed is built, so skipReasonFor's needs branch no
      // longer catches it first — it falls through to the killed-app
      // branch and joins b3_killed here, in gallery order.
      expect(appKillOnly.map((s) => s.id), ['b3_killed', 'f5_deeplink_killed']);
    });

    test('the skip buckets add up to thirty-four, with none unclassified', () {
      final needsCount = scenarioGallery
          .where((s) => _skipBucket(s) == 'needs')
          .length;
      final iosCount = scenarioGallery
          .where((s) => _skipBucket(s) == 'ios')
          .length;
      final appKillCount = scenarioGallery
          .where((s) => _skipBucket(s) == 'appKill')
          .length;
      final unclassified = scenarioGallery.where(
        (s) => _skipBucket(s) == 'unclassified',
      );
      final skippedCount = scenarioGallery
          .where((s) => skipReasonFor(s) != null)
          .length;

      // A non-empty bucket here means skipReasonFor grew a reason to skip
      // that none of needs/platform/requiresKilledApp accounts for — the
      // classifier and the function it mirrors have drifted apart.
      expect(unclassified, isEmpty);

      // The buckets must not drift apart from the totals the file already
      // pins above: 28 + 4 + 2 is the 34 skipped, and 34 + 32 is the
      // catalogue's 66.
      expect(
        needsCount + iosCount + appKillCount + unclassified.length,
        skippedCount,
      );
      expect(skippedCount, 34);
      expect(skippedCount + 32, 66);
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
