import 'package:fcm_app/domains/notifications/shared_preferences_notification_group_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesNotificationGroupStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesNotificationGroupStore();
  });

  test('starts empty', () async {
    expect(await store.load(), isEmpty);
  });

  test('round-trips groups and their members', () async {
    await store.save({
      'builds': ['msg-1', 'msg-2'],
    });

    expect(await store.load(), {
      'builds': ['msg-1', 'msg-2'],
    });
  });

  test(
    'replaces rather than merging, so the caller owns the membership',
    () async {
      await store.save({
        'builds': ['msg-1'],
      });

      await store.save({
        'builds': ['msg-2'],
      });

      expect(await store.load(), {
        'builds': ['msg-2'],
      });
    },
  );

  test('clear empties every group', () async {
    await store.save({
      'builds': ['msg-1'],
      'alerts': ['msg-2'],
    });

    await store.clear();

    expect(
      await store.load(),
      isEmpty,
      reason:
          'the Clear button wipes the tray, and a count that outlived the '
          'notifications it counted would claim a tally that no longer exists',
    );
  });

  test('drops one unreadable group rather than the whole store', () async {
    await SharedPreferencesAsync().setString(
      'notifications.groups',
      '{"builds":["msg-1"],"broken":"not a list"}',
    );

    expect(
      (await store.load()).keys,
      ['builds'],
      reason:
          'one entry this build cannot read must not cost the counts of every '
          'other group',
    );
  });

  test('survives a value that is not JSON at all', () async {
    await SharedPreferencesAsync().setString(
      'notifications.groups',
      'not json',
    );

    expect(await store.load(), isEmpty);
  });
}
