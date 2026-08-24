import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/pending_reply.dart';
import '../entities/reply_store.dart';

/// A [ReplyStore] over `shared_preferences`.
///
/// [SharedPreferencesAsync] for the reason `SharedPreferencesPushPayloadStore`
/// gives: the legacy API caches per isolate, and the notification-response
/// isolate is not the UI isolate, so a cached UI-side snapshot would never see
/// what it appended.
class SharedPreferencesReplyStore implements ReplyStore {
  SharedPreferencesReplyStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> appendPending(PendingReply reply) async {
    final stored =
        await _preferences.getStringList(_pendingKey) ?? const <String>[];

    await _preferences.setStringList(_pendingKey, [
      ...stored,
      jsonEncode(reply.toJson()),
    ]);
  }

  @override
  Future<List<PendingReply>> takePending() async {
    // Not atomic: `getStringList` and `remove` are two platform calls, so an
    // `appendPending` landing between them can be lost or replayed. See the
    // `ReplyStore` class doc for why that window is tolerable.
    final stored =
        await _preferences.getStringList(_pendingKey) ?? const <String>[];
    await _preferences.remove(_pendingKey);

    final replies = <PendingReply>[];
    for (final entry in stored) {
      final reply = _decodePending(entry);
      // One entry this build cannot read costs that entry alone.
      if (reply != null) {
        replies.add(reply);
      }
    }

    return replies;
  }

  @override
  Future<Map<String, String>> load() async {
    final stored = await _preferences.getString(_repliesKey);
    if (stored == null) {
      return const {};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException catch (error) {
      debugPrint('Dropping corrupt replies: ${error.message}');

      return const {};
    }
    if (decoded is! Map<String, Object?>) {
      return const {};
    }

    final replies = <String, String>{};
    for (final entry in decoded.entries) {
      final text = entry.value;
      // One entry this build cannot read costs that entry alone.
      if (text is String) {
        replies[entry.key] = text;
      }
    }

    return replies;
  }

  @override
  Future<void> save(Map<String, String> replies) =>
      _preferences.setString(_repliesKey, jsonEncode(replies));
}

const _pendingKey = 'push.pendingReplies';
const _repliesKey = 'push.replies';

/// Decodes one stored pending entry, or null when it is not a reply this build
/// understands — one corrupt entry must not cost the whole queue.
PendingReply? _decodePending(String entry) {
  try {
    return PendingReply.fromJson(jsonDecode(entry));
  } on FormatException catch (error) {
    debugPrint('Dropping a corrupt pending reply: ${error.message}');

    return null;
  }
}
