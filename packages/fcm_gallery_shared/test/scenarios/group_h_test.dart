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

/// The `android.notification` block of [scenario]'s template.
Map<Object?, Object?> androidNotificationOf(Scenario scenario) {
  final android = scenario.payloadTemplate['android']! as Map<Object?, Object?>;

  return android['notification']! as Map<Object?, Object?>;
}

/// The one scenario in group H carrying [id].
Scenario scenarioH(String id) => groupH.firstWhere((s) => s.id == id);

void main() {
  group('group H', () {
    test('offers all five intrusive-delivery scenarios, in order', () {
      expect(groupH.map((s) => s.id), [
        'h1_dnd_bypass',
        'h2_category_alarm',
        'h3_ios_time_sensitive',
        'h4_ios_critical',
        'h5_ios_passive',
      ]);
    });

    test('only the two safe iOS interruption levels work today', () {
      // hasLength(5) backs the word "two". `isSupported` is just `needs.isEmpty`, so
      // it passes for any blocked entries carrying any needs at all, including ones
      // filed under the wrong sub-project — hence needs pinned exactly.
      expect(groupH, hasLength(5));

      const expected = {
        'h1_dnd_bypass': [ScenarioNeed.channels, ScenarioNeed.externalApproval],
        'h2_category_alarm': [ScenarioNeed.channels],
        'h3_ios_time_sensitive': <ScenarioNeed>[],
        'h4_ios_critical': [ScenarioNeed.externalApproval],
        'h5_ios_passive': <ScenarioNeed>[],
      };

      for (final scenario in groupH) {
        expect(scenario.needs, expected[scenario.id], reason: scenario.id);
      }

      expect(groupH.where((s) => s.isSupported).map((s) => s.id), [
        'h3_ios_time_sensitive',
        'h5_ios_passive',
      ]);
    });

    test('h4 is permanently blocked on Apple, not on us', () {
      final critical = scenarioH('h4_ios_critical');

      expect(critical.needs, [ScenarioNeed.externalApproval]);
      expect(critical.isSupported, isFalse);

      // `contains('entitlement')` passes on prose saying the opposite. The expectation
      // is checked to attribute the block to Apple and to say the entry is listed
      // rather than scheduled — the one thing that distinguishes externalApproval.
      final expectation = critical.expectation;
      expect(expectation, isNotNull);
      expect(expectation, contains('critical-alert entitlement'));
      expect(expectation, contains('Apple must approve'));
      expect(expectation, contains('rather than scheduled'));
    });

    test('the interruption level rides in the free-form aps dictionary', () {
      // FCM has no field for it, which is why apns.payload is untyped.
      //
      // The level alone is not the whole contract: APNs needs priority 10 for a level
      // that alerts, so a time-sensitive push sent at 5 is held like the ordinary
      // notification it means to break past. The header is pinned beside each level
      // as a String, apns.headers being a typed map<string, string>.
      for (final (id, level, priority) in const [
        ('h3_ios_time_sensitive', 'time-sensitive', '10'),
        ('h4_ios_critical', 'critical', '10'),
        ('h5_ios_passive', 'passive', '5'),
      ]) {
        final scenario = scenarioH(id);

        expect(apsOf(scenario)['interruption-level'], level, reason: id);

        final headerPriority = apnsHeadersOf(scenario)['apns-priority'];
        expect(headerPriority, isA<String>(), reason: id);
        expect(headerPriority, priority, reason: id);
      }
    });

    test('h4 asks for a critical sound with the two types APNs defines', () {
      // The only guard on these two: apns.payload is free-form, so the round-trip
      // preserves whatever it is given, and `expect(x, 1)` is satisfied by 1.0. APNs
      // wants `critical` as the int 1 and `volume` as a double, so the two differ.
      final sound = apsOf(scenarioH('h4_ios_critical'))['sound'];
      expect(sound, isA<Map<Object?, Object?>>());

      final soundMap = sound! as Map<Object?, Object?>;
      expect(soundMap['critical'], isA<int>());
      expect(soundMap['critical'], 1);
      expect(soundMap['volume'], isA<double>());
      expect(soundMap['volume'], 1.0);
      expect(soundMap['name'], 'default');
    });

    test('the two working levels differ in whether they alert at all', () {
      // The pair is only worth two entries while they differ on the device: h3 must
      // sound to prove it broke through Focus, and h5 must not.
      final timeSensitive = apsOf(scenarioH('h3_ios_time_sensitive'));
      expect(timeSensitive['sound'], 'default');

      final passive = apsOf(scenarioH('h5_ios_passive'));
      expect(passive.containsKey('sound'), isFalse);
      expect(passive.containsKey('badge'), isFalse);
    });

    test('the Android half breaks through by channel, not by payload', () {
      // Android has no per-message interruption level — bypassing DND is a channel
      // property — so both Android entries must name a channel and ask for HIGH.
      for (final id in const ['h1_dnd_bypass', 'h2_category_alarm']) {
        final scenario = scenarioH(id);
        final android =
            scenario.payloadTemplate['android']! as Map<Object?, Object?>;

        expect(android['priority'], 'HIGH', reason: id);

        final channelId = androidNotificationOf(scenario)['channel_id'];
        expect(channelId, isA<String>(), reason: id);
        expect((channelId! as String).trim(), isNotEmpty, reason: id);

        expect(
          scenario.payloadTemplate.containsKey('apns'),
          isFalse,
          reason: id,
        );
        expect(scenario.needs, contains(ScenarioNeed.channels), reason: id);
      }

      // FCM's data map is map<string, string>, so h2's category rides as a
      // string; the round-trip catches a bare symbol, this names the value.
      final alarm = scenarioH('h2_category_alarm');
      final data = alarm.payloadTemplate['data']! as Map<Object?, Object?>;
      expect(data['category'], 'alarm');
    });

    test('nothing in this group is about the killed app', () {
      // The question here is whether the system lets the alert through, not what
      // state the app was in, so every entry is observable in the foreground. The
      // flag would drag in delayed sending.
      for (final scenario in groupH) {
        expect(scenario.requiresKilledApp, isFalse, reason: scenario.id);
        expect(scenario.defaultDelaySeconds, 0, reason: scenario.id);
      }
    });

    test('the whole group reaches the gallery', () {
      final galleryIds = scenarioGallery.map((s) => s.id).toSet();

      for (final scenario in groupH) {
        expect(galleryIds, contains(scenario.id), reason: scenario.id);
      }
    });
  });
}
