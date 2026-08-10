import 'notification_delivery.dart';
import 'notification_event.dart';

/// Everything the sandbox lets you decide about a message.
///
/// This is the value the editor edits, the value a gallery scenario supplies as
/// a starting point, and the value that travels inside
/// `SendNotificationRequest`. It carries no ids and no timestamp: those are
/// stamped by the function, so the app has no authority over what it is about
/// to receive.
class NotificationDraft {
  const NotificationDraft({
    required this.event,
    required this.title,
    required this.body,
    this.data = const {},
    this.delivery = const NotificationDelivery(),
  });

  /// Reads a draft written by [toJson].
  ///
  /// Throws [FormatException] on a missing or unknown event. Extra data values
  /// are stringified because FCM data payloads are `String`-valued on the wire
  /// anyway, so coercing here is closer to the truth than rejecting.
  factory NotificationDraft.fromJson(Map<String, dynamic> json) {
    final rawEvent = json['event'] as String?;
    final event = rawEvent == null
        ? null
        : NotificationEvent.fromWireName(rawEvent);
    if (event == null) {
      throw FormatException('Unknown notification event: $rawEvent');
    }

    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        data['${entry.key}'] = '${entry.value}';
      }
    }

    final rawDelivery = json['delivery'];

    return NotificationDraft(
      event: event,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: Map.unmodifiable(data),
      delivery: rawDelivery is Map<String, dynamic>
          ? NotificationDelivery.fromJson(rawDelivery)
          : const NotificationDelivery(),
    );
  }

  /// The archetype this message stands for. Travels as the `event` data key.
  final NotificationEvent event;

  /// Notification title, and the `title` data key.
  final String title;

  /// Notification body, and the `body` data key.
  final String body;

  /// Extra data keys, passed through to the device untouched.
  final Map<String, String> data;

  /// How the message should reach the device.
  final NotificationDelivery delivery;

  NotificationDraft copyWith({
    NotificationEvent? event,
    String? title,
    String? body,
    Map<String, String>? data,
    NotificationDelivery? delivery,
  }) =>
      NotificationDraft(
        event: event ?? this.event,
        title: title ?? this.title,
        body: body ?? this.body,
        data: data ?? this.data,
        delivery: delivery ?? this.delivery,
      );

  Map<String, dynamic> toJson() => {
        'event': event.wireName,
        'title': title,
        'body': body,
        'data': data,
        'delivery': delivery.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is NotificationDraft &&
      event == other.event &&
      title == other.title &&
      body == other.body &&
      delivery == other.delivery &&
      _sameData(other.data);

  @override
  int get hashCode =>
      Object.hash(event, title, body, delivery, data.length);

  @override
  String toString() =>
      'NotificationDraft(event: ${event.wireName}, title: $title, '
      'delivery: $delivery, extra keys: ${data.keys.toList()})';

  bool _sameData(Map<String, String> other) {
    if (data.length != other.length) {
      return false;
    }

    for (final entry in data.entries) {
      if (other[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
