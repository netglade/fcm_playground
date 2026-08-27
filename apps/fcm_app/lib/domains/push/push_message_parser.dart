import 'package:fcm_app/domains/push/push_message.dart';
import 'package:fcm_app/domains/push/push_message_format_exception.dart';

/// Turns the flat `data` map of an FCM message into a [PushMessage].
///
/// FCM data payloads are always `Map<String, String>` on the wire, but the
/// plugin surfaces them as `Map<String, Object?>`, so every field is validated
/// here rather than cast blindly.
///
/// This file and its three siblings — [PushMessage],
/// [PushMessageFormatException] and `notification_action.dart` — import nothing
/// but `dart:core` and each other, which `dart_core_only_test.dart` enforces by
/// reading their import lines. It keeps payload validity testable with no
/// device, binding or Firebase project; one Flutter import here removes that.
class PushMessageParser {
  const PushMessageParser();

  /// Keys this parser reads itself; anything else passes through in
  /// [PushMessage.data].
  ///
  /// `trace_id` and `scenario_id` are plumbing the send API injects, so listing
  /// either as "extra data" would credit the sender with a detail of ours.
  /// Neither is required: a hand-sent push has no trace id and no scenario.
  ///
  /// `tag` joins them as the real `android.notification.tag` the app keys its
  /// drawing on, not something the sender typed into `data`.
  static const reservedKeys = {
    'id',
    'title',
    'body',
    'sentAt',
    'trace_id',
    'scenario_id',
    'tag',
  };

  /// `id` de-duplicates repeat deliveries and `sentAt` orders the inbox, so
  /// neither can be inferred. `title` and `body` are optional — a data-only
  /// push has neither.
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

  /// A data-only push has no title or body, so an empty headline is a value, not
  /// a fault. A wrong-typed one still is.
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
