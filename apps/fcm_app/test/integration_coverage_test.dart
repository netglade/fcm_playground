import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/expected_events.dart';

/// Which of [skipReasonFor]'s three branches a skipped [scenario] falls under,
/// `'unclassified'` if none do, or null when it runs.
///
/// Mirrors that function's order over the same fields rather than a list of ids, so
/// an unblocked scenario drops out of its bucket instead of staying miscounted. The
/// fall-through is a real outcome: a fourth reason to skip lands here rather than
/// silently joining `'appKill'`, and the sum assertion catches it.
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
      // What one-file-per-group costs and this buys back: a new scenario fails
      // here until the suite accounts for it.
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

    test('runs thirty-six scenarios and skips thirty of sixty-six', () {
      final running = scenarioGallery.where((s) => skipReasonFor(s) == null);

      // Literals, because the split is a claim the spec makes — a scenario
      // becoming unblocked should surface here rather than be absorbed.
      expect(scenarioGallery, hasLength(66));
      expect(running, hasLength(36));
      expect(scenarioGallery.length - running.length, 30);
    });

    test('a blocked scenario is skipped for its own need, named in words', () {
      final blocked = scenarioGallery.firstWhere(
        (s) => s.needs.contains(ScenarioNeed.targeting),
      );

      // The bare enum name, not the prose the UI shows — right for a test
      // report.
      expect(skipReasonFor(blocked), contains('targeting'));
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

        // No needs, so a reported need here would mean the skip policy is
        // reading the wrong field.
        expect(killed.needs, isEmpty);
        expect(skipReasonFor(killed), contains('killed'));
      },
    );

    test('every expectation names the send-side pair', () {
      // A send always records queued and then sent or send_failed, so an
      // expectation missing those asserts less than the pipeline guarantees.
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

    test('twenty-four scenarios are skipped for an unbuilt ScenarioNeed', () {
      final blockedByNeed = scenarioGallery.where(
        (s) => _skipBucket(s) == 'needs',
      );

      expect(blockedByNeed, hasLength(24));
    });

    test('four scenarios are skipped for being iOS-only', () {
      final iosOnly = scenarioGallery.where((s) => _skipBucket(s) == 'ios');

      expect(iosOnly, hasLength(4));
    });

    test('two scenarios are skipped only for needing the app killed', () {
      final appKillOnly = scenarioGallery.where(
        (s) => _skipBucket(s) == 'appKill',
      );

      // f5_deeplink_killed has no need left, so it falls past the needs branch
      // into the killed-app one, joining b3_killed in gallery order.
      expect(appKillOnly.map((s) => s.id), ['b3_killed', 'f5_deeplink_killed']);
    });

    test('the skip buckets add up to thirty, with none unclassified', () {
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

      // Non-empty means skipReasonFor grew a reason none of the three branches
      // accounts for — the classifier and the function have drifted apart.
      expect(unclassified, isEmpty);

      // The buckets must agree with the totals pinned above: 24 + 4 + 2 = 30
      // skipped, and 30 + 36 = 66.
      expect(
        needsCount + iosCount + appKillCount + unclassified.length,
        skippedCount,
      );
      expect(skippedCount, 30);
      expect(skippedCount + 36, 66);
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
