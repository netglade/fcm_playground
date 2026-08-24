import 'package:fcm_app/domains/push/data_sources/shared_preferences_reply_store.dart';
import 'package:fcm_app/domains/push/entities/pending_reply.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesReplyStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesReplyStore();
  });

  test('starts empty on both collections', () async {
    expect(await store.takePending(), isEmpty);
    expect(await store.load(), isEmpty);
  });

  test('appends pending replies in order and drains them once', () async {
    await store.appendPending(const PendingReply('msg-1', 'first'));
    await store.appendPending(const PendingReply('msg-2', 'second'));

    expect((await store.takePending()).map((reply) => reply.text), [
      'first',
      'second',
    ]);
    expect(
      await store.takePending(),
      isEmpty,
      reason: 'draining twice would replay a reply the app already merged',
    );
  });

  test('round-trips the merged map', () async {
    await store.save({'msg-1': 'ready when you are'});

    expect(await store.load(), {'msg-1': 'ready when you are'});
  });

  test(
    'replaces the map rather than merging, so the caller owns pruning',
    () async {
      await store.save({'msg-1': 'first'});

      await store.save({'msg-2': 'second'});

      expect((await store.load()).keys, ['msg-2']);
    },
  );

  test(
    'drops one unreadable pending entry rather than the whole queue',
    () async {
      await SharedPreferencesAsync().setStringList('push.pendingReplies', [
        'not json',
        '{"messageId":"msg-2","text":"kept"}',
      ]);

      expect(
        (await store.takePending()).map((reply) => reply.text),
        ['kept'],
        reason:
            'one corrupt entry must cost that entry alone, as it does for stored '
            'payloads',
      );
    },
  );

  test('drops a pending entry missing a field', () async {
    await SharedPreferencesAsync().setStringList('push.pendingReplies', [
      '{"messageId":"msg-1"}',
      '{"text":"orphan"}',
    ]);

    expect(await store.takePending(), isEmpty);
  });
}
