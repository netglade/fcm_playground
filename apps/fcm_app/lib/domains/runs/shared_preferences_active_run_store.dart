import 'package:shared_preferences/shared_preferences.dart';

import 'active_run_store.dart';

/// An [ActiveRunStore] over `shared_preferences`.
///
/// [SharedPreferencesAsync] rather than the legacy API, for the reason
/// `SharedPreferencesDeviceIdentity` records: the legacy one caches per isolate, and
/// this value is written by the UI and read after a cold start.
class SharedPreferencesActiveRunStore implements ActiveRunStore {
  SharedPreferencesActiveRunStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> activeRunId() async {
    final stored = await _preferences.getString(_key);

    return stored == null || stored.isEmpty ? null : stored;
  }

  @override
  Future<void> setActiveRunId(String runId) =>
      _preferences.setString(_key, runId);

  @override
  Future<void> clear() => _preferences.remove(_key);
}

/// Namespaced so a future preference cannot collide with it.
const _key = 'runs.active_run_id';
