import 'package:collection/collection.dart';

import 'json_field.dart';

/// The editable body of a push: what the Sandbox form holds, and what
/// `POST /send` receives.
///
/// Immutable, so a draft handed to a sender cannot change underneath it while
/// the request is in flight.
class NotificationDraft {
  const NotificationDraft({
    required this.title,
    required this.body,
    this.data = const {},
  });

  /// Reads the flat request shape. Absent `title`/`body` become blank so the
  /// validator can name them; a wrong *type* is a [FormatException].
  factory NotificationDraft.fromJson(Map<String, dynamic> json) =>
      NotificationDraft(
        title: readOptionalText(json['title'], 'title'),
        body: readOptionalText(json['body'], 'body'),
        data: readStringMap(json['data'], 'data'),
      );

  /// Notification title, and the `title` data key.
  final String title;

  /// Notification body, and the `body` data key.
  final String body;

  /// Extra data keys, passed through to the payload untouched.
  final Map<String, String> data;

  /// Writes the flat request shape `POST /send` accepts.
  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'data': data};

  /// Returns a copy with the given fields replaced.
  NotificationDraft copyWith({
    String? title,
    String? body,
    Map<String, String>? data,
  }) => NotificationDraft(
    title: title ?? this.title,
    body: body ?? this.body,
    data: data ?? this.data,
  );

  @override
  bool operator ==(Object other) {
    if (other is! NotificationDraft) {
      return false;
    }

    return title == other.title &&
        body == other.body &&
        _dataEquality.equals(data, other.data);
  }

  @override
  int get hashCode => Object.hash(title, body, _dataEquality.hash(data));

  @override
  String toString() => 'NotificationDraft(title: $title, data: ${data.keys})';
}

/// `core` compares its own maps with a hand-rolled helper; this package uses
/// `package:collection` instead of copying it, so there is one implementation
/// here rather than a second copy of the same loop.
const _dataEquality = MapEquality<String, String>();
