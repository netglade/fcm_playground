import 'push_message.dart';
import 'push_message_format_exception.dart';

/// Turns the flat `data` map of an FCM message into a [PushMessage].
///
/// FCM data payloads are always `Map<String, String>` on the wire, but the
/// plugin surfaces them as `Map<String, Object?>`, so every field is validated
/// here rather than cast blindly.
///
/// This file and its three siblings — [PushMessage], [PushMessageFormatException]
/// and `notification_action.dart` — depend on nothing but `dart:core` and each
/// other. They used to live in a separate package, which enforced that; now an
/// import test in `apps/fcm_app/test/domains/push` does, by reading each file's
/// own `import` lines. Keeping the constraint true costs nothing on its own —
/// what it buys is that the rules for what makes a payload valid could be
/// tested with no device, no Flutter binding and no Firebase project, if a
/// future split ever wanted them isolated again — and a Flutter import here
/// would quietly take that away.
class PushMessageParser {
  const PushMessageParser();

  /// Keys this parser reads itself; anything else is passed through in
  /// [PushMessage.data].
  ///
  /// `trace_id` and `scenario_id` are plumbing the send API injects, so showing
  /// either as an "extra data" row would present a detail of ours as something the
  /// sender chose. Neither is in [requiredKeys] — a push sent by hand has no trace
  /// id, and a hand-composed payload belongs to no scenario.
  ///
  /// `tag` joins them for the same reason: it is the real `android.notification.tag`
  /// field the app reads to key its own drawing, not a value the sender typed into
  /// `data`.
  static const reservedKeys = {
    'id',
    'title',
    'body',
    'sentAt',
    'trace_id',
    'scenario_id',
    'tag',
  };

  /// `id` de-duplicates repeat deliveries and `sentAt` orders the inbox, so neither
  /// can be inferred. `title` and `body` are absent from a data-only push, so they
  /// are read as optional.
  static const requiredKeys = {'id', 'sentAt'};

  /// Parses [payload], or throws [PushMessageFormatException] if a required
  /// field is missing, empty, or the wrong shape.
  PushMessage parse(Map<String, Object?> payload) {
    final data = <String, String>{};
    for (final entry in payload.entries) {
      if (!reservedKeys.contains(entry.key)) {
        data[entry.key] = '${entry.value}';
      }
    }

    return PushMessage(
      id: _requireText(payload, 'id'),
      title: _optionalText(payload, 'title'),
      body: _optionalText(payload, 'body'),
      sentAt: _requireTimestamp(payload, 'sentAt'),
      data: Map.unmodifiable(data),
      tag: _optionalText(payload, 'tag').trim().isEmpty
          ? null
          : _optionalText(payload, 'tag').trim(),
    );
  }

  String _requireText(Map<String, Object?> payload, String field) {
    final value = payload[field];
    if (value == null) {
      throw PushMessageFormatException(field, 'missing');
    }
    if (value is! String) {
      throw PushMessageFormatException(
        field,
        'expected a String, got ${value.runtimeType}',
      );
    }
    if (value.trim().isEmpty) {
      throw PushMessageFormatException(field, 'must not be blank');
    }

    return value;
  }

  /// A data-only push carries no title and no body, so an empty headline is a value
  /// rather than a fault. A wrong-typed value still is one.
  String _optionalText(Map<String, Object?> payload, String field) {
    final value = payload[field];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw PushMessageFormatException(
        field,
        'expected a String, got ${value.runtimeType}',
      );
    }

    return value;
  }

  DateTime _requireTimestamp(Map<String, Object?> payload, String field) {
    final raw = _requireText(payload, field);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw PushMessageFormatException(
        field,
        'expected an ISO-8601 timestamp, got "$raw"',
      );
    }

    return parsed.toUtc();
  }
}
