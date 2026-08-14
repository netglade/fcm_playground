import 'package:fcm_app/telemetry/new_device_id.dart';
import 'package:fcm_app/telemetry/shared_preferences_device_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync preferences;
  late SharedPreferencesDeviceIdentity identity;

  // A second handset: its own platform store, captured by its own
  // SharedPreferencesAsync, so nothing it writes can reach [preferences].
  SharedPreferencesDeviceIdentity freshInstall() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    return SharedPreferencesDeviceIdentity(
      preferences: SharedPreferencesAsync(),
    );
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    identity = SharedPreferencesDeviceIdentity(preferences: preferences);
  });

  group('the id', () {
    test('generates an id once and keeps it', () async {
      final first = await identity.id();

      expect(await identity.id(), first);
      expect(first, isNotEmpty);
    });

    test('is written to preferences, not merely held in memory', () async {
      // The key name is spelled out rather than imported: it is the address the
      // id lives at across upgrades, and renaming it would hand every existing
      // install a new identity and split its matrix column in two.
      final minted = await identity.id();

      expect(await preferences.getString('telemetry.device_id'), minted);
    });

    test('survives a new instance over the same preferences', () async {
      // The id is only useful if it outlives a restart; otherwise every launch
      // is a new device and the matrix grows a column a day.
      final first = await identity.id();

      expect(
        await SharedPreferencesDeviceIdentity(preferences: preferences).id(),
        first,
      );
    });

    test('two concurrent first calls agree on one id', () async {
      // A batch of events flushed from two call sites must not carry two device
      // ids because both raced the initial read.
      final both = await Future.wait([identity.id(), identity.id()]);

      expect(both.first, both.last);
      expect(await preferences.getString('telemetry.device_id'), both.first);
    });

    test('a fresh install gets a different id', () async {
      // Two handsets must be two columns in the matrix.
      final mine = await identity.id();
      final other = freshInstall();

      expect(await other.id(), isNot(mine));
      // And the two stores really are separate: neither overwrote the other.
      expect(await identity.id(), mine);
    });

    test('is untouched by setting a label', () async {
      final minted = await identity.id();

      await identity.setLabel('Xiaomi 13');

      expect(await identity.id(), minted);
      expect(
        await SharedPreferencesDeviceIdentity(preferences: preferences).id(),
        minted,
      );
    });
  });

  group('minting an id', () {
    // These pin the property the store cannot demonstrate on its own: that the
    // difference between two ids comes from randomness rather than from the
    // clock having moved between the two calls.
    final instant = DateTime.utc(2026, 8, 14, 9, 30);

    test('differs for two ids minted at the very same instant', () {
      expect(newDeviceId(instant), isNot(newDeviceId(instant)));
    });

    test('a thousand ids for one instant are all distinct', () {
      // A generator with only a few bits of entropy passes the pairwise test
      // often enough to look fine; it cannot pass this one.
      final ids = {for (var i = 0; i < 1000; i++) newDeviceId(instant)};

      expect(ids, hasLength(1000));
    });

    test('carries the instant, so ids read in the order they were made', () {
      final earlier = newDeviceId(instant);
      final later = newDeviceId(instant.add(const Duration(microseconds: 1)));

      expect(earlier.split('-').first, isNot(later.split('-').first));
      expect(newDeviceId(instant).split('-').first, earlier.split('-').first);
    });

    test('is hex and dashes only, so it is safe in JSON and FCM data', () {
      expect(
        newDeviceId(instant),
        matches(RegExp(r'^[0-9a-f]+(-[0-9a-f]+)+$')),
      );
    });

    test('is long enough to be a device identifier', () {
      // 16 hex digits of secure randomness beyond the timestamp.
      expect(newDeviceId(instant).split('-').last, hasLength(16));
    });
  });

  group('the label', () {
    test('starts with an empty label and keeps what is set', () async {
      // Empty rather than a guess: no automatic value is as useful as
      // "Xiaomi 13" typed by someone who knows which handset is on the desk.
      expect(await identity.label(), isEmpty);

      await identity.setLabel('Xiaomi 13');

      expect(await identity.label(), 'Xiaomi 13');
    });

    test('replaces the previous label rather than appending', () async {
      await identity.setLabel('Xiaomi 13');

      await identity.setLabel('Pixel 8');

      expect(await identity.label(), 'Pixel 8');
    });

    test('is written to preferences and survives a new instance', () async {
      await identity.setLabel('Xiaomi 13');

      expect(
        await preferences.getString('telemetry.device_label'),
        'Xiaomi 13',
      );
      expect(
        await SharedPreferencesDeviceIdentity(preferences: preferences).label(),
        'Xiaomi 13',
      );
    });

    test('a fresh install starts empty again', () async {
      await identity.setLabel('Xiaomi 13');

      expect(await freshInstall().label(), isEmpty);
    });
  });
}
