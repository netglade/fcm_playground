import 'package:fcm_app/domains/push/shared_preferences_pressed_action_store.dart';
import 'package:fcm_app/domains/push/pressed_action.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesPressedActionStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesPressedActionStore();
  });

  test('starts empty', () async {
    expect(await store.load(), isEmpty);
  });

  test('round-trips a press with the state it came from', () async {
    await store.save({
      'msg-1': const PressedAction(actionId: 'retry', from: OpenedFrom.killed),
    });

    final loaded = await store.load();

    expect(loaded, {
      'msg-1': const PressedAction(actionId: 'retry', from: OpenedFrom.killed),
    });
  });

  test('replaces rather than merges, so the caller owns the pruning', () async {
    await store.save({
      'msg-1': const PressedAction(actionId: 'retry', from: OpenedFrom.killed),
    });

    await store.save({
      'msg-2': const PressedAction(
        actionId: 'open',
        from: OpenedFrom.foreground,
      ),
    });

    expect((await store.load()).keys, ['msg-2']);
  });

  test('drops one unreadable entry rather than the whole store', () async {
    await SharedPreferencesAsync().setString(
      'push.pressedActions',
      '{"msg-1":{"actionId":"retry","from":"sideways"},'
          '"msg-2":{"actionId":"open","from":"killed"}}',
    );

    final loaded = await store.load();

    expect(
      loaded.keys,
      ['msg-2'],
      reason:
          'an unknown OpenedFrom is a value this build cannot read, and losing '
          'every other press with it would be worse than losing the one',
    );
  });

  test(
    "drops an entry whose 'from' is not a String, rather than the whole store",
    () async {
      await SharedPreferencesAsync().setString(
        'push.pressedActions',
        '{"msg-1":{"actionId":"retry","from":42},'
            '"msg-2":{"actionId":"open","from":"killed"}}',
      );

      final loaded = await store.load();

      expect(
        loaded.keys,
        ['msg-2'],
        reason:
            "a non-String 'from' is a value this build cannot read, and losing "
            'every other press with it would be worse than losing the one',
      );
    },
  );

  test('survives a value that is not JSON at all', () async {
    await SharedPreferencesAsync().setString('push.pressedActions', 'not json');

    expect(await store.load(), isEmpty);
  });
}
