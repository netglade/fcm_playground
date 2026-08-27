import 'package:fcm_gallery_shared/src/json_field.dart';
import 'package:fcm_gallery_shared/src/runs/scheduled_run_item.dart';

/// A group of sends created by one action.
///
/// A single delayed send is a run of one. That is the whole reason there is one
/// type here rather than two: the countdown and the batch travel the same code, and
/// a batch report is an object rather than a correlation the client has to invent
/// from N unrelated trace ids.
class ScheduledRun {
  ScheduledRun({
    required this.id,
    required DateTime createdAt,
    required this.items,
  }) : createdAt = createdAt.toUtc();

  factory ScheduledRun.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    if (items is! List) {
      throw FormatException('"items" must be a list, got ${items.runtimeType}');
    }

    return ScheduledRun(
      id: requireText(json['run_id'], 'run_id'),
      createdAt: requireTimestamp(json['created_at'], 'created_at'),
      items: [
        for (final (index, item) in items.indexed)
          ScheduledRunItem.fromJson(requireObject(item, 'items[$index]')),
      ],
    );
  }

  final String id;

  final DateTime createdAt;

  /// In index order, which is also due order.
  final List<ScheduledRunItem> items;

  /// This run with [item] in place of the one at its index.
  ///
  /// A whole-run replacement rather than a mutation, so a store can persist the
  /// result and a cubit can hold the previous one without the two aliasing.
  ScheduledRun withItem(ScheduledRunItem item) => ScheduledRun(
    id: id,
    createdAt: createdAt,
    items: [
      for (final existing in items)
        if (existing.index == item.index) item else existing,
    ],
  );

  Map<String, Object?> toJson() => {
    'run_id': id,
    'created_at': createdAt.toIso8601String(),
    'items': [for (final item in items) item.toJson()],
  };

  @override
  String toString() => 'ScheduledRun($id, ${items.length} items)';
}
