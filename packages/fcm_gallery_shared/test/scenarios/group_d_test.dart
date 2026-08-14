import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `channel_id` group D files [scenario] under.
///
/// Reaches through `android.notification` with `!`, so a missing block fails the
/// test rather than silently reading as null.
Object? channelIdOf(Scenario scenario) {
  final android = scenario.payloadTemplate['android']! as Map;
  final notification = android['notification']! as Map;

  return notification['channel_id'];
}

void main() {
  group('group D', () {
    test('offers all eight channel and importance scenarios, in order', () {
      expect(groupD.map((s) => s.id), [
        'd1_importance_high',
        'd2_importance_default',
        'd3_importance_low',
        'd4_importance_min',
        'd5_custom_sound',
        'd6_vibration_pattern',
        'd7_channel_immutability',
        'd8_channel_group',
      ]);
    });

    test('all eight are blocked on channel work, and on nothing else', () {
      for (final scenario in groupD) {
        expect(scenario.needs, [ScenarioNeed.channels], reason: scenario.id);
        expect(scenario.isSupported, isFalse, reason: scenario.id);
        // The channels work needs no killed app: the importance of a channel is
        // observable while the app is running, so the flag would only mislead.
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
      }
    });

    test('each names a distinct, non-blank channel — that is the variable', () {
      // Uniqueness alone would pass for the wrong reason: an entry that omitted
      // channel_id contributes null, and a single null is as "distinct" as any
      // string. Each id is therefore pinned as a non-blank String first, so the
      // set comparison can only ever be comparing real channel names.
      final channelIds = <Object?>[];
      for (final scenario in groupD) {
        final channelId = channelIdOf(scenario);
        expect(channelId, isA<String>(), reason: scenario.id);
        expect(channelId, isNotEmpty, reason: scenario.id);
        channelIds.add(channelId);
      }

      expect(channelIds.toSet(), hasLength(channelIds.length));
    });

    test('d6 opts out of the channel default before setting a pattern', () {
      // Setting vibrate_timings without clearing default_vibrate_timings is the
      // classic way to get the channel's own buzz and conclude the payload was
      // ignored, so both fields are pinned together.
      final pattern = groupD.firstWhere((s) => s.id == 'd6_vibration_pattern');
      final notification =
          (pattern.payloadTemplate['android']! as Map)['notification']! as Map;

      expect(notification['default_vibrate_timings'], isFalse);

      // Proto durations, never numbers: 400 would be a 400 from Google. Matched
      // on the whole shape rather than endsWith('s'), which '0.4 seconds' and
      // 'abcs' would both satisfy.
      final duration = RegExp(r'^\d+(\.\d+)?s$');
      final timings = notification['vibrate_timings']! as List;
      expect(timings, isNotEmpty);
      for (final timing in timings) {
        expect(timing, isA<String>(), reason: '$timing');
        expect(timing, matches(duration), reason: '$timing');
      }
    });

    test('d5 names the custom sound on the channel it introduces', () {
      final sound = groupD.firstWhere((s) => s.id == 'd5_custom_sound');
      final notification =
          (sound.payloadTemplate['android']! as Map)['notification']! as Map;

      expect(notification['sound'], isNotNull);
      expect(sound.expectation, contains('res/raw'));
    });

    test('d7 states that Android ignores the change, and names the fix', () {
      // NOT "the immutability scenario is versioned": its own channel is
      // chat_v1, so that name would be false. And contains('ignore') alone
      // would be satisfied by prose saying the opposite ("do not ignore"),
      // while contains('_v2') is satisfied by any token ending in _v2 — both
      // are pinned to the phrase that carries the meaning.
      final immutable = groupD.firstWhere(
        (s) => s.id == 'd7_channel_immutability',
      );

      expect(channelIdOf(immutable), 'chat_v1');
      expect(immutable.description, contains('ignore the change'));
      expect(immutable.expectation, contains('chat_v2'));
      expect(channelIdOf(groupD.last), 'chat_v2', reason: 'the fix d7 names');
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupD) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
