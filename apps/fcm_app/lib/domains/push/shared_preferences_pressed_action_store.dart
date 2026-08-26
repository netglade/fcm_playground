import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pressed_action.dart';
import 'pressed_action_store.dart';

/// A [PressedActionStore] over `shared_preferences`.
///
/// [SharedPreferencesAsync] for the reason `SharedPreferencesPushPayloadStore`
/// gives: the legacy API caches per isolate.
class SharedPreferencesPressedActionStore implements PressedActionStore {
  SharedPreferencesPressedActionStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, PressedAction>> load() async {
    final stored = await _preferences.getString(_key);
    if (stored == null) {
      return const {};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException catch (error) {
      debugPrint('Dropping corrupt pressed actions: ${error.message}');

      return const {};
    }
    if (decoded is! Map<String, Object?>) {
      return const {};
    }

    final actions = <String, PressedAction>{};
    for (final entry in decoded.entries) {
      final action = PressedAction.fromJson(entry.value);
      // One entry this build cannot read costs that entry alone.
      if (action != null) {
        actions[entry.key] = action;
      }
    }

    return actions;
  }

  @override
  Future<void> save(Map<String, PressedAction> actions) =>
      _preferences.setString(
        _key,
        jsonEncode({
          for (final entry in actions.entries) entry.key: entry.value.toJson(),
        }),
      );
}

const _key = 'push.pressedActions';
