import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `apns` block of [scenario]'s template.
///
/// Reaches through with `!`, so an entry missing the block fails the test
/// rather than reading as null.
Map<Object?, Object?> apnsOf(Scenario scenario) =>
    scenario.payloadTemplate['apns']! as Map<Object?, Object?>;

/// The `apns.headers` map of [scenario]'s template.
Map<Object?, Object?> apnsHeadersOf(Scenario scenario) =>
    apnsOf(scenario)['headers']! as Map<Object?, Object?>;

/// The `apns.payload.aps` dictionary of [scenario]'s template.
Map<Object?, Object?> apsOf(Scenario scenario) {
  final payload = apnsOf(scenario)['payload']! as Map<Object?, Object?>;

  return payload['aps']! as Map<Object?, Object?>;
}

/// The one scenario in group I carrying [id].
Scenario scenarioI(String id) => groupI.firstWhere((s) => s.id == id);

void main() {
  group('group I', () {
    test('offers all four silent-delivery scenarios, in order', () {
      expect(groupI.map((s) => s.id), [
        'i1_silent_no_sound',
        'i2_silent_data_sync',
        'i3_ios_content_available',
        'i4_burst',
      ]);
    });

    test('only the two data scenarios work today', () {
      // hasLength(4) is what backs the word "two": without it a fifth entry
      // could be appended and the filtered list below would still be about the
      // four checked here. And `where(isSupported)` alone cannot carry the
      // name — isSupported is only `needs.isEmpty`, so it passes for any two
      // blocked entries carrying any non-empty needs at all, including two
      // filed under the wrong sub-project. Each entry's needs are therefore
      // pinned exactly, so "which scenarios does the channels work unblock?"
      // answers truthfully.
      expect(groupI, hasLength(4));

      const expected = {
        'i1_silent_no_sound': [ScenarioNeed.channels],
        'i2_silent_data_sync': <ScenarioNeed>[],
        'i3_ios_content_available': <ScenarioNeed>[],
        'i4_burst': [ScenarioNeed.manualStep],
      };

      for (final scenario in groupI) {
        expect(scenario.needs, expected[scenario.id], reason: scenario.id);
      }

      expect(groupI.where((s) => s.isSupported).map((s) => s.id), [
        'i2_silent_data_sync',
        'i3_ios_content_available',
      ]);
    });

    test('the iOS background push sets content-available and low priority', () {
      // Both are required together: content-available without apns-priority 5
      // is throttled harder, and Apple documents the pair. apns-push-type is
      // pinned beside it because APNs requires the header on every push and
      // rejects a background one declared as an alert.
      final headers = apnsHeadersOf(scenarioI('i3_ios_content_available'));

      // apns.headers is a typed map<string, string>, so a bare 5 is a parse
      // failure rather than a silent success; asserting the type documents it.
      expect(headers['apns-priority'], isA<String>());
      expect(headers['apns-priority'], '5');
      expect(headers['apns-push-type'], 'background');

      final available = apsOf(
        scenarioI('i3_ios_content_available'),
      )['content-available'];

      // isA<int>() beside the value, for the reason group G records: `1.0 == 1`
      // is true in Dart, and apns.payload is free-form so the round-trip
      // preserves a double unchanged. This is the only guard on the type, and
      // APNs treats a non-integer content-available as absent.
      expect(available, isA<int>());
      expect(available, 1);
    });

    test('the iOS background push shows nothing, which is the whole point', () {
      // A background push carries no alert: APNs rejects apns-push-type
      // background alongside an alert, and a `notification` block would have
      // FCM synthesise one. Either would turn this into an ordinary visible
      // push and quietly stop testing background refresh at all.
      final background = scenarioI('i3_ios_content_available');

      expect(background.payloadTemplate.containsKey('notification'), isFalse);
      expect(apsOf(background).containsKey('alert'), isFalse);
      expect(apsOf(background).containsKey('sound'), isFalse);
    });

    test('the sync scenario draws nothing and carries what it syncs', () {
      // "Invisible" is the entire claim, so `data` must be the only block: an
      // android.notification or apns.alert block would be drawn by the system
      // and the entry would stop demonstrating a silent sync. Checking only
      // for the absence of `notification` would miss both of those.
      final sync = scenarioI('i2_silent_data_sync');

      expect(sync.payloadTemplate.keys.toSet(), {'data'});

      // The handler's observable effect is the row it writes, so the payload
      // has to give it something to write.
      final data = sync.payloadTemplate['data']! as Map<Object?, Object?>;
      expect(data, isNotEmpty);
      expect(data['event'], 'sync');
    });

    test('the burst scenario says how many and how fast', () {
      // `contains('20')` would NOT do: a bare 20 turns up in unrelated prose —
      // a package name, a date, a timeout — so it proves neither the count nor
      // the rate, and the rate is the whole scenario. Twenty pushes spread over
      // an afternoon is not a burst. Both halves are pinned to the words that
      // carry them.
      final burst = scenarioI('i4_burst');

      expect(burst.needs, contains(ScenarioNeed.manualStep));

      final steps = burst.manualSteps;
      expect(steps, isNotNull);
      expect(steps!.trim(), isNotEmpty);
      expect(steps, contains('20 times'));
      expect(steps, contains('within 10 seconds'));
    });

    test('nothing in this group is about the killed app', () {
      // Tempting here, because a silent data push is the one thing that still
      // runs with no UI — but each entry is observable with the app in the
      // foreground, so the flag would be false. It means "meaningless unless
      // the app is killed" and drags in delayed sending, so it is pinned off
      // across the group rather than left to the gallery-wide invariant, which
      // only checks the entries that set it.
      for (final scenario in groupI) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
        expect(
          scenario.needs,
          isNot(contains(ScenarioNeed.delayedSend)),
          reason: scenario.id,
        );
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupI) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
