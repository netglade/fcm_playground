import '../send_message_request.dart';

/// The most items one run may hold. The catalogue has 66, so selecting all of them
/// fits; the cap is there to stop a typo scheduling a hundred thousand sends.
const maxRunItems = 100;

/// An hour. Past that the countdown screen stops being a countdown, and a schedule
/// nobody is waiting at is what `missed` exists for.
const maxRunSeconds = 3600;

/// The body of `POST /runs`.
class ScheduleRunRequest {
  const ScheduleRunRequest({
    required this.delaySeconds,
    required this.items,
    this.spacingSeconds = 0,
  });

  /// Every limit is enforced here rather than in the router, so the app's own
  /// scheduler and a `curl` are refused by one rule with one message.
  factory ScheduleRunRequest.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    if (items is! List) {
      throw FormatException('"items" must be a list, got ${items.runtimeType}');
    }
    if (items.isEmpty) {
      throw const FormatException('"items" must hold at least one message');
    }
    if (items.length > maxRunItems) {
      throw FormatException(
        '"items" holds ${items.length} messages, and $maxRunItems is the most a '
        'run may schedule',
      );
    }

    return ScheduleRunRequest(
      delaySeconds: _seconds(json['delay_seconds'], 'delay_seconds'),
      spacingSeconds: json['spacing_seconds'] == null
          ? 0
          : _seconds(json['spacing_seconds'], 'spacing_seconds'),
      items: [for (final (index, item) in items.indexed) _item(item, index)],
    );
  }

  /// How long to hold the first item for.
  final int delaySeconds;

  /// Added again for each item after the first, so a batch arrives spread out
  /// rather than as one burst FCM may collapse.
  final int spacingSeconds;

  final List<SendMessageRequest> items;

  Map<String, Object?> toJson() => {
    'delay_seconds': delaySeconds,
    'spacing_seconds': spacingSeconds,
    'items': [for (final item in items) item.toJson()],
  };
}

/// Prefixes the item's position onto whatever `SendMessageRequest` reports, so a
/// bad payload in a batch of sixty-six is findable rather than merely named.
SendMessageRequest _item(Object? value, int index) {
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'items[$index] must be an object, got ${value.runtimeType}',
    );
  }

  try {
    return SendMessageRequest.fromJson(value);
  } on FormatException catch (error) {
    throw FormatException('items[$index]: ${error.message}');
  }
}

int _seconds(Object? value, String field) {
  if (value is! int) {
    throw FormatException(
      '"$field" must be a whole number of seconds, got ${value.runtimeType}',
    );
  }
  if (value < 0 || value > maxRunSeconds) {
    throw FormatException(
      '"$field" must be between 0 and $maxRunSeconds, got $value',
    );
  }

  return value;
}
