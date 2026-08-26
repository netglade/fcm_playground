import 'package:shared_preferences/shared_preferences.dart';

import 'device_identity.dart';
import 'new_device_id.dart';

/// A [DeviceIdentity] over `shared_preferences`.
///
/// [SharedPreferencesAsync] rather than the legacy `SharedPreferences` for the
/// same reason as `SharedPreferencesPushPayloadStore`: the legacy API caches per
/// isolate, and a background-recorded event must stamp the same device id as a
/// foreground one.
class SharedPreferencesDeviceIdentity implements DeviceIdentity {
  SharedPreferencesDeviceIdentity({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  /// The in-flight or completed read, held so two concurrent first calls cannot
  /// mint two ids and have the second write win. Cleared on failure, so a
  /// transient storage error does not poison the instance.
  Future<String>? _id;

  @override
  Future<String> id() => _id ??= _mintOnce();

  @override
  Future<String> label() async => await _preferences.getString(_labelKey) ?? '';

  @override
  Future<void> setLabel(String label) =>
      _preferences.setString(_labelKey, label);

  Future<String> _mintOnce() async {
    try {
      return await _readOrMint();
    } on Object {
      _id = null;
      rethrow;
    }
  }

  Future<String> _readOrMint() async {
    final stored = await _preferences.getString(_idKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final minted = newDeviceId(DateTime.now().toUtc());
    await _preferences.setString(_idKey, minted);

    return minted;
  }
}

/// Namespaced so a future preference cannot collide with them, and stable
/// forever: renaming either key hands every existing install a new identity.
const _idKey = 'telemetry.device_id';
const _labelKey = 'telemetry.device_label';
