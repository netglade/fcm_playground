import 'package:fcm_app/domains/push/shared_preferences_push_payload_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesPushPayloadStore store;

  Map<String, Object?> payload(String id) => {
    'id': id,
    'title': 'Build finished',
    'body': 'main #128 passed',
    'sentAt': '2026-08-11T09:30:00.000Z',
  };

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesPushPayloadStore();
  });

  group('the inbox key', () {
    test('starts empty', () async {
      expect(await store.loadInbox(), isEmpty);
    });

    test('round-trips payloads in the order they were saved', () async {
      await store.saveInbox([payload('a'), payload('b')]);

      final loaded = await store.loadInbox();

      expect(loaded.map((entry) => entry['id']), ['a', 'b']);
      expect(loaded.first['title'], 'Build finished');
    });

    test(
      'replaces rather than appends, so the cap the caller applied holds',
      () async {
        await store.saveInbox([payload('a'), payload('b')]);

        await store.saveInbox([payload('c')]);

        expect((await store.loadInbox()).map((entry) => entry['id']), ['c']);
      },
    );
  });

  group('the pending key', () {
    test('starts empty', () async {
      expect(await store.takePending(), isEmpty);
    });

    test('accumulates appended payloads', () async {
      await store.appendPending(payload('a'));
      await store.appendPending(payload('b'));

      expect((await store.takePending()).map((entry) => entry['id']), [
        'a',
        'b',
      ]);
    });

    test('clears on take, so a payload cannot be drained twice', () async {
      await store.appendPending(payload('a'));

      await store.takePending();

      expect(await store.takePending(), isEmpty);
    });

    test('is independent of the inbox key', () async {
      await store.saveInbox([payload('kept')]);

      await store.appendPending(payload('pending'));
      await store.takePending();

      expect((await store.loadInbox()).single['id'], 'kept');
    });
  });

  group('corruption', () {
    test('skips an entry that is not JSON and keeps the rest', () async {
      await SharedPreferencesAsync().setStringList('push.inbox', [
        'not json at all',
        '{"id":"good","title":"t","body":"b","sentAt":"2026-08-11T09:30:00.000Z"}',
      ]);

      final loaded = await store.loadInbox();

      expect(loaded.single['id'], 'good');
    });

    test('skips an entry that is JSON but not an object', () async {
      await SharedPreferencesAsync().setStringList('push.inbox', ['[1,2,3]']);

      expect(await store.loadInbox(), isEmpty);
    });
  });
}
