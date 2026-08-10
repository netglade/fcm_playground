import 'notification_priority.dart';

/// How a message should reach the device, as opposed to what it says.
///
/// Grouping these two together keeps `NotificationDraft` inside the parameter
/// budget the shared DCM configuration allows, and they belong together anyway:
/// a silent message and a visible one are two different delivery modes, not two
/// unrelated flags.
class NotificationDelivery {
  const NotificationDelivery({
    this.asNotification = true,
    this.priority = NotificationPriority.high,
  });

  /// Reads a delivery written by [toJson].
  ///
  /// Throws [FormatException] on an unknown priority rather than defaulting:
  /// silently downgrading a message the caller asked to be urgent is worse than
  /// refusing it.
  factory NotificationDelivery.fromJson(Map<String, dynamic> json) {
    final rawPriority = json['priority'] as String?;
    final priority = rawPriority == null
        ? null
        : NotificationPriority.fromWireName(rawPriority);
    if (priority == null) {
      throw FormatException('Unknown notification priority: $rawPriority');
    }

    return NotificationDelivery(
      asNotification: json['asNotification'] as bool? ?? true,
      priority: priority,
    );
  }

  /// Whether FCM should show a notification. `false` sends a data-only push,
  /// which arrives silently and wakes the app instead.
  final bool asNotification;

  /// The delivery priority requested from FCM.
  final NotificationPriority priority;

  NotificationDelivery copyWith({
    bool? asNotification,
    NotificationPriority? priority,
  }) => NotificationDelivery(
    asNotification: asNotification ?? this.asNotification,
    priority: priority ?? this.priority,
  );

  Map<String, dynamic> toJson() => {
    'asNotification': asNotification,
    'priority': priority.wireName,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationDelivery &&
      asNotification == other.asNotification &&
      priority == other.priority;

  @override
  int get hashCode => Object.hash(asNotification, priority);

  @override
  String toString() =>
      'NotificationDelivery(asNotification: $asNotification, '
      'priority: ${priority.wireName})';
}
