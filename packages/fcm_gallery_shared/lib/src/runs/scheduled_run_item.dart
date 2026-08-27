import 'package:fcm_gallery_shared/src/json_field.dart';
import 'package:fcm_gallery_shared/src/runs/run_item_state.dart';
import 'package:fcm_gallery_shared/src/send_message_request.dart';
import 'package:fcm_gallery_shared/src/telemetry/telemetry.dart';

/// One send inside a run: what to send, when it is due, and what became of it.
///
/// It is a [SendMessageRequest] plus a due time and an outcome, so a scheduled
/// message is validated by exactly the rules an immediate one is — an unknown field
/// is refused with its path, and a template setting its own delivery target is
/// refused outright.
class ScheduledRunItem {
  /// Normalises both timestamps to UTC. A `dueAt` left on local time would fire
  /// hours early or late depending on where the server is.
  ScheduledRunItem({
    required this.index,
    required this.request,
    required DateTime dueAt,
    this.state = RunItemState.pending,
    this.traceId,
    this.messageId,
    this.error,
    DateTime? dispatchedAt,
    this.events = const [],
  }) : dueAt = dueAt.toUtc(),
       dispatchedAt = dispatchedAt?.toUtc();

  factory ScheduledRunItem.fromJson(Map<String, Object?> json) {
    final events = json['events'] as List<Object?>? ?? const [];

    return ScheduledRunItem(
      index: requireInt(json['index'], 'index'),
      request: SendMessageRequest.fromJson(
        requireObject(json['request'], 'request'),
      ),
      dueAt: requireTimestamp(json['due_at'], 'due_at'),
      state: RunItemState.fromWireName(requireText(json['state'], 'state')),
      traceId: _text(json['trace_id']),
      messageId: _text(json['message_id']),
      error: _text(json['error']),
      dispatchedAt: json['dispatched_at'] == null
          ? null
          : requireTimestamp(json['dispatched_at'], 'dispatched_at'),
      events: [
        for (final (index, event) in events.indexed)
          TelemetryEvent.fromJson(requireObject(event, 'events[$index]')),
      ],
    );
  }

  /// Position within the run, which is also the order the items come due in.
  final int index;

  final SendMessageRequest request;

  /// Absolute, never a delay. After a restart the scheduler has to know when this
  /// *should* have fired, which a stored relative delay could not say.
  final DateTime dueAt;

  final RunItemState state;

  /// Minted by the scheduler and written *before* the send, so an interrupted
  /// dispatch can be resolved by reading this trace out of the telemetry store.
  final String? traceId;

  /// FCM's own name for the message, once it accepted one.
  final String? messageId;

  /// Why it failed, safe to show as-is.
  final String? error;

  final DateTime? dispatchedAt;

  /// This item's telemetry, filled in by `GET /runs/{id}` alone. The store never
  /// persists it — the events live in the telemetry database, and a second copy
  /// here is one that can disagree with them.
  final List<TelemetryEvent> events;

  /// This item with the given fields replaced.
  ///
  /// It cannot *clear* a field, and does not need to: an outcome is only ever
  /// filled in, never taken back.
  ScheduledRunItem copyWith({
    RunItemState? state,
    String? traceId,
    String? messageId,
    String? error,
    DateTime? dispatchedAt,
    List<TelemetryEvent>? events,
  }) => ScheduledRunItem(
    index: index,
    request: request,
    dueAt: dueAt,
    state: state ?? this.state,
    traceId: traceId ?? this.traceId,
    messageId: messageId ?? this.messageId,
    error: error ?? this.error,
    dispatchedAt: dispatchedAt ?? this.dispatchedAt,
    events: events ?? this.events,
  );

  /// Omits the optional fields rather than writing nulls, as every DTO in this
  /// package does. `events` is omitted when empty, which is how it is stored.
  Map<String, Object?> toJson() => {
    'index': index,
    'request': request.toJson(),
    'due_at': dueAt.toIso8601String(),
    'state': state.wireName,
    'trace_id': ?traceId,
    'message_id': ?messageId,
    'error': ?error,
    'dispatched_at': ?dispatchedAt?.toIso8601String(),
    if (events.isNotEmpty)
      'events': [for (final event in events) event.toJson()],
  };

  @override
  String toString() => 'ScheduledRunItem($index ${state.wireName} due $dueAt)';
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
