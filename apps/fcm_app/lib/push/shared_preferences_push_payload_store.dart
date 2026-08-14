import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_payload_store.dart';

/// A [PushPayloadStore] over `shared_preferences`.
///
/// Uses [SharedPreferencesAsync] rather than the legacy `SharedPreferences` for
/// a reason that is load-bearing, not stylistic: the legacy API keeps an
/// in-memory cache per isolate, and the background message handler runs in its
/// own engine instance. A cached UI-side snapshot would never see what the
/// background isolate appended, so every untapped background push would be
/// silently lost. This API holds no cache and reads platform storage each call.
class SharedPreferencesPushPayloadStore implements PushPayloadStore {
  SharedPreferencesPushPayloadStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Map<String, Object?>>> loadInbox() => _read(_inboxKey);

  @override
  Future<void> saveInbox(List<Map<String, Object?>> payloads) =>
      _preferences.setStringList(_inboxKey, payloads.map(jsonEncode).toList());

  @override
  Future<void> appendPending(Map<String, Object?> payload) async {
    final stored =
        await _preferences.getStringList(_pendingKey) ?? const <String>[];

    await _preferences.setStringList(_pendingKey, [
      ...stored,
      jsonEncode(payload),
    ]);
  }

  @override
  Future<List<Map<String, Object?>>> takePending() async {
    final payloads = await _read(_pendingKey);
    await _preferences.remove(_pendingKey);

    return payloads;
  }

  Future<List<Map<String, Object?>>> _read(String key) async {
    final stored = await _preferences.getStringList(key) ?? const <String>[];
    final payloads = <Map<String, Object?>>[];
    for (final entry in stored) {
      final decoded = _decodePayload(entry);
      if (decoded != null) {
        payloads.add(decoded);
      }
    }

    return payloads;
  }
}

/// Namespaced so a future preference cannot collide with them.
const _inboxKey = 'push.inbox';
const _pendingKey = 'push.pending';

/// Decodes one stored entry, or null when it is not a JSON object.
///
/// One corrupt entry must not cost the whole inbox, so it is skipped and logged
/// rather than thrown.
Map<String, Object?>? _decodePayload(String entry) {
  try {
    final decoded = jsonDecode(entry);
    if (decoded is! Map<String, Object?>) {
      debugPrint('Dropping a stored payload that is not an object: $entry');

      return null;
    }

    return decoded;
  } on FormatException catch (error) {
    debugPrint('Dropping a corrupt stored payload: ${error.message}');

    return null;
  }
}
