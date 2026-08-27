import 'dart:convert';

import 'package:fcm_app/domains/notifications/notification_group_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [NotificationGroupStore] over `shared_preferences`.
///
/// [SharedPreferencesAsync] for the reason `SharedPreferencesReplyStore` gives:
/// the legacy API caches per isolate, and this store is read from both the UI
/// isolate and the FCM background-message isolate, so a cached snapshot in one
/// would never see the other's write.
class SharedPreferencesNotificationGroupStore
    implements NotificationGroupStore {
  SharedPreferencesNotificationGroupStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, List<String>>> load() async {
    final stored = await _preferences.getString(_groupsKey);
    if (stored == null) {
      return const {};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException catch (error) {
      debugPrint('Dropping corrupt notification groups: ${error.message}');

      return const {};
    }
    if (decoded is! Map<String, Object?>) {
      return const {};
    }

    final groups = <String, List<String>>{};
    for (final entry in decoded.entries) {
      final members = entry.value;
      // One entry this build cannot read costs that entry alone.
      if (members is List && members.every((member) => member is String)) {
        groups[entry.key] = members.cast<String>();
      } else {
        debugPrint('Dropping unreadable notification group "${entry.key}"');
      }
    }

    return groups;
  }

  @override
  Future<void> save(Map<String, List<String>> groups) =>
      _preferences.setString(_groupsKey, jsonEncode(groups));

  @override
  Future<void> clear() => _preferences.remove(_groupsKey);
}

const _groupsKey = 'notifications.groups';
