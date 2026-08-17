import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The `apns` block of [scenario]'s template. Reaches through with `!`, so a missing
/// block fails the test rather than reading as null.
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
      // hasLength(4) backs the word "two". `isSupported` is only `needs.isEmpty`, so
      // it passes for any blocked entries carrying any needs at all, including ones
      // filed under the wrong sub-project — hence needs pinned exactly.
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
      // Apple documents the pair: content-available without apns-priority 5 is
      // throttled harder, and APNs rejects a background push declared as an alert.
      final headers = apnsHeadersOf(scenarioI('i3_ios_content_available'));

      // apns.headers is a typed map<string, string>, so a bare 5 is a parse
      // failure rather than a silent success; asserting the type documents it.
      expect(headers['apns-priority'], isA<String>());
      expect(headers['apns-priority'], '5');
      expect(headers['apns-push-type'], 'background');

      final available = apsOf(
        scenarioI('i3_ios_content_available'),
      )['content-available'];

      // isA<int>() beside the value: `1.0 == 1` is true in Dart and apns.payload is
      // free-form, and APNs treats a non-integer content-available as absent.
      expect(available, isA<int>());
      expect(available, 1);
    });

    test('the iOS background push shows nothing, which is the whole point', () {
      // APNs rejects apns-push-type background alongside an alert, and a
      // `notification` block would have FCM synthesise one — either turns this into
      // an ordinary visible push.
      final background = scenarioI('i3_ios_content_available');

      expect(background.payloadTemplate.containsKey('notification'), isFalse);
      expect(apsOf(background).containsKey('alert'), isFalse);
      expect(apsOf(background).containsKey('sound'), isFalse);
    });

    test('the sync scenario draws nothing and carries what it syncs', () {
      // `data` must be the only block: an android.notification or apns.alert block
      // would be drawn by the system, and neither is caught by checking for the
      // absence of `notification` alone.
      final sync = scenarioI('i2_silent_data_sync');

      expect(sync.payloadTemplate.keys.toSet(), {'data'});

      // The handler's observable effect is the row it writes, so the payload
      // has to give it something to write.
      final data = sync.payloadTemplate['data']! as Map<Object?, Object?>;
      expect(data, isNotEmpty);
      expect(data['event'], 'sync');
    });

    test('the burst scenario says how many and how fast', () {
      // `contains('20')` proves neither the count nor the rate, and the rate is the
      // whole scenario — twenty pushes over an afternoon is not a burst.
      final burst = scenarioI('i4_burst');

      expect(burst.needs, contains(ScenarioNeed.manualStep));

      final steps = burst.manualSteps;
      expect(steps, isNotNull);
      expect(steps!.trim(), isNotEmpty);
      expect(steps, contains('20 times'));
      expect(steps, contains('within 10 seconds'));
    });

    test('nothing in this group is about the killed app', () {
      // Tempting here, since a silent data push still runs with no UI — but each
      // entry is observable in the foreground, so the flag would be false and would
      // drag in delayed sending.
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
