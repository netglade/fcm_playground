import 'package:fcm_app/domains/runs/data_sources/shared_preferences_active_run_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesActiveRunStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesActiveRunStore(
      preferences: SharedPreferencesAsync(),
    );
  });

  test('holds nothing before a run is scheduled', () async {
    expect(await store.activeRunId(), isNull);
  });

  test(
    'remembers a run id across a fresh instance, which is the point',
    () async {
      await store.setActiveRunId('run-1');

      final relaunched = SharedPreferencesActiveRunStore(
        preferences: SharedPreferencesAsync(),
      );

      expect(await relaunched.activeRunId(), 'run-1');
    },
  );

  test('keeps only the newest run, so a stale one cannot reopen', () async {
    await store.setActiveRunId('run-1');
    await store.setActiveRunId('run-2');

    expect(await store.activeRunId(), 'run-2');
  });

  test('clears, and clearing twice is not an error', () async {
    await store.setActiveRunId('run-1');

    await store.clear();
    await store.clear();

    expect(await store.activeRunId(), isNull);
  });
}
