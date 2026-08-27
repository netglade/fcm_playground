import 'dart:async';

import 'package:fcm_app/domains/notifications/notifications.dart';
import 'package:fcm_app/domains/push/pending_reply.dart';
import 'package:fcm_app/domains/push/pressed_action.dart';
import 'package:fcm_app/domains/push/pressed_action_store.dart';
import 'package:fcm_app/domains/push/push_message.dart';
import 'package:fcm_app/domains/push/push_message_format_exception.dart';
import 'package:fcm_app/domains/push/push_message_parser.dart';
import 'package:fcm_app/domains/push/push_payload_store.dart';
import 'package:fcm_app/domains/push/push_source.dart';
import 'package:fcm_app/domains/push/reply_store.dart';
import 'package:fcm_app/domains/push/silent_pressed_action_store.dart';
import 'package:fcm_app/domains/push/silent_reply_store.dart';
import 'package:fcm_app/domains/telemetry/telemetry.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/inbox/cubit/cubit.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

/// Everything about received pushes that outlives a page: the subscription,
/// ordering, de-duplication and persistence.
///
/// App-scoped rather than a cubit, because a push arrives whichever tab is
/// showing and the Sandbox needs the token this holds.
class PushRepository {
  PushRepository(
    this._source, {
    required this._store,
    this._presenter = const SilentNotificationPresenter(),
    this._telemetry = const SilentPushTelemetry(),
    this._pressedActions = const SilentPressedActionStore(),
    ReplyStore replies = const SilentReplyStore(),
    this._setupError,
  }) : _replyStore = replies;

  static const maxStoredMessages = 100;

  final PushSource _source;
  final PushPayloadStore _store;
  final NotificationPresenter _presenter;
  final PushTelemetry _telemetry;
  final PressedActionStore _pressedActions;
  // `_replyStore`, not `_replies` — the merged map below needs that name.
  final ReplyStore _replyStore;
  final _parser = const PushMessageParser();
  final _pressed = <String, PressedAction>{};
  final _replies = <String, String>{};
  final _accepted = <_AcceptedPush>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  // Broadcast: the shell and the inbox page both watch it.
  //
  // `sync: true` is load-bearing — an async controller delivers via a microtask
  // in the *subscriber's* zone, so anything subscribed in a widget test's
  // `setUp` never hears a thing.
  final _changes = StreamController<InboxState>.broadcast(sync: true);
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _setupError;
  String? _token;
  String? _pendingOpenId;

  /// A tap whose message was not held yet — the Android warm start, where FCM
  /// reports the tap before the payload is drained.
  ///
  /// Carries the state because nothing else will remember it. Cleared once
  /// reported, so one press cannot record two opens.
  ({String id, OpenedFrom from, String? actionId})? _unreportedOpen;

  Stream<InboxState> get changes => _changes.stream;

  InboxState get state => InboxState(
    messages: messages,
    rejections: rejections,
    token: _token,
    setupError: _setupError,
    pendingOpenId: _pendingOpenId,
    pressedActions: Map.unmodifiable(_pressed),
    replies: Map.unmodifiable(_replies),
  );

  String? get setupError => _setupError;

  List<PushMessage> get messages =>
      List.unmodifiable(_accepted.map((push) => push.message));

  List<String> get rejections => List.unmodifiable(_rejections);

  String? get token => _token;

  bool get hasPendingOpen => _pendingOpenId != null;

  /// The message a tap asked to open, or null when no tap is outstanding or its
  /// message is not held.
  ///
  /// Resolved on every read: the tap and the payload come from two streams, so
  /// the message may land after the request.
  PushMessage? get pendingOpen => state.pendingOpen;

  void requestOpen(String id, OpenedFrom from, {String? actionId}) {
    _pendingOpenId = id;
    // The trace id lives on the payload, so an unresolvable tap is held until
    // the payload turns up rather than recorded against a fabricated trace.
    final opened = _acceptedFor(id);
    _unreportedOpen = opened == null
        ? (id: id, from: from, actionId: actionId)
        : null;
    // After `_unreportedOpen`, so `_savePressed`'s prune sees this tap as
    // outstanding rather than deleting the press it was just given.
    if (actionId != null) {
      _pressed[id] = PressedAction(actionId: actionId, from: from);
      unawaited(_savePressed());
    }
    if (opened != null) {
      unawaited(
        reportAndFlush(
          _telemetry,
          TelemetryEventType.opened,
          opened.payload,
          detail: from.wireName,
        ),
      );
      if (actionId != null) {
        unawaited(
          reportAndFlush(
            _telemetry,
            TelemetryEventType.action,
            opened.payload,
            detail: actionId,
          ),
        );
      }
    }
    _publish();
  }

  /// Records that the user swiped the notification for [id] away.
  ///
  /// Publishes nothing — the message stays in the inbox, because the tray and
  /// the inbox are different lists. An id not held records nothing, unlike a
  /// tap: there is no screen to open afterwards.
  void reportDismissed(String id) {
    final dismissed = _acceptedFor(id);
    if (dismissed == null) {
      return;
    }

    unawaited(
      reportAndFlush(
        _telemetry,
        TelemetryEventType.dismissed,
        dismissed.payload,
      ),
    );
  }

  /// Called by the shell once it has navigated, so it does not navigate twice.
  ///
  /// Published like any other change: the tap is a field of the snapshot on
  /// [changes], so a silent clear would leave watchers still claiming a tap is
  /// outstanding.
  void clearPendingOpen() {
    _pendingOpenId = null;
    _publish();
  }

  void listen() {
    _subscription = _source.payloads.listen(_onLivePayload);
  }

  /// Loads the kept messages and everything the background isolate left.
  ///
  /// A storage failure surfaces in [setupError] rather than throwing —
  /// persistence failing must not stop the app opening.
  Future<void> restore() async {
    try {
      final stored = await _store.loadInbox();
      final pending = await _store.takePending();
      // Stored payloads are newest first and each ingest inserts at the front,
      // so they go in reversed. Pending were appended oldest first.
      for (final payload in stored.reversed) {
        _ingest(payload, notify: false);
      }
      for (final payload in pending) {
        _ingest(payload, notify: false);
      }
      await _save();
      _pressed.addAll(await _pressedActions.load());
      await _savePressed();
      _replies.addAll(await _replyStore.load());
      // Runs even with nothing pending: a reply loaded above may point at a
      // message the cap has evicted, and that must be pruned too.
      await _mergeReplies(await _replyStore.takePending());
    } catch (error) {
      // The global `t`, not `context.t` — no `BuildContext` here, same as the
      // `http_*` data sources. `SetupErrorBanner` still redraws on a locale
      // change, via `InboxView`'s own `context.t`-watching build.
      _setupError ??= t.inbox.setup_error(error: error);
      _publish();
    }
  }

  /// Merges anything the background isolate appended since the last drain.
  ///
  /// Payloads first, replies second, and the order is load-bearing: a reply
  /// answering a push from this same drain must find its message held, or
  /// [_saveReplies] prunes it immediately.
  ///
  /// [_mergeReplies] runs outside the empty check — a reply action does not
  /// foreground the app, so a resume often carries a reply and no payload.
  Future<void> drainPending() async {
    final pending = await _store.takePending();
    if (pending.isNotEmpty) {
      for (final payload in pending) {
        _ingest(payload, notify: false);
      }
      await _save();
    }

    await _mergeReplies(await _replyStore.takePending());
    _publish();
  }

  Future<void> refreshToken() async {
    try {
      _token = await _source.token();
    } catch (error) {
      debugPrint('Could not read FCM token: $error');
      _token = null;
    }
    _publish();
  }

  /// Releases the push subscription and stops publishing.
  ///
  /// Both closes are unawaited deliberately: `close()` only completes once a
  /// listener takes the done event, so awaiting an unlistened controller — the
  /// ordinary case in a test — never returns.
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_changes.close());
  }

  void _onLivePayload(Map<String, Object?> payload) {
    // Before parsing, and only for the live stream: a rejected payload still
    // arrived. Restored and drained payloads were already recorded as
    // `received_bg` when they landed.
    unawaited(
      reportAndFlush(_telemetry, TelemetryEventType.receivedFg, payload),
    );
    _ingest(payload, notify: true);
    unawaited(_save());
  }

  void _ingest(Map<String, Object?> payload, {required bool notify}) {
    try {
      final message = _parser.parse(payload);
      if (_seenIds.add(message.id)) {
        _accepted.insert(0, _AcceptedPush(message, payload));
        if (_accepted.length > maxStoredMessages) {
          // The evicted id stays in _seenIds, so a re-delivery cannot
          // resurrect it mid-session. A restart rebuilds the set.
          _accepted.removeLast();
        }
        if (notify) {
          unawaited(_show(message, payload));
        }
        if (_unreportedOpen case final open? when message.id == open.id) {
          _unreportedOpen = null;
          unawaited(
            reportAndFlush(
              _telemetry,
              TelemetryEventType.opened,
              payload,
              detail: open.from.wireName,
            ),
          );
          if (open.actionId case final actionId?) {
            _pressed[message.id] = PressedAction(
              actionId: actionId,
              from: open.from,
            );
            unawaited(_savePressed());
            unawaited(
              reportAndFlush(
                _telemetry,
                TelemetryEventType.action,
                payload,
                detail: actionId,
              ),
            );
          }
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    _publish();
  }

  /// Draws the banner for [message], and reports it only once that has worked.
  ///
  /// A `displayed` recorded before [show] returned would claim a notification a
  /// failing presenter never drew.
  Future<void> _show(PushMessage message, Map<String, Object?> payload) async {
    try {
      await _presenter.show(message);
    } on Object catch (error) {
      debugPrint('No banner for ${message.id}: $error');

      return;
    }

    await reportAndFlush(_telemetry, TelemetryEventType.displayed, payload);
  }

  _AcceptedPush? _acceptedFor(String id) {
    for (final push in _accepted) {
      if (push.message.id == id) {
        return push;
      }
    }

    return null;
  }

  Future<void> _save() =>
      _store.saveInbox(_accepted.map((push) => push.payload).toList());

  /// Writes the presses for messages still held, or still awaiting one,
  /// dropping the rest.
  ///
  /// Pruning keeps the store bounded by [maxStoredMessages]: a press whose
  /// message was evicted can never be shown again. [_unreportedOpen] can push
  /// it one over, briefly.
  Future<void> _savePressed() async {
    _pressed.removeWhere(
      (id, _) => _acceptedFor(id) == null && id != _unreportedOpen?.id,
    );

    await _pressedActions.save(Map.of(_pressed));
  }

  /// Merges [pending], records one `action` event per reply whose message is
  /// held, then re-persists.
  ///
  /// A reply opens no app, so produces no tap and never reaches [requestOpen] —
  /// this is the only place the event gets a real trace id. Its timestamp is
  /// the drain, not the typing, so latency from it measures the wrong
  /// interval.
  Future<void> _mergeReplies(List<PendingReply> pending) async {
    for (final reply in pending) {
      _replies[reply.messageId] = reply.text;
      if (_acceptedFor(reply.messageId) case final accepted?) {
        unawaited(
          reportAndFlush(
            _telemetry,
            TelemetryEventType.action,
            accepted.payload,
            detail: reply.actionId,
          ),
        );
      }
    }
    await _saveReplies();
  }

  /// Writes the merged replies for messages still held, dropping the rest.
  ///
  /// Bounded like [_savePressed]. Needs no holding field only because
  /// [drainPending] and [restore] ingest payloads before merging replies —
  /// [drainPending] once had that backwards and lost a reply.
  Future<void> _saveReplies() async {
    _replies.removeWhere((id, _) => _acceptedFor(id) == null);
    await _replyStore.save(Map.of(_replies));
  }

  void _publish() {
    _changes.add(state);
  }
}

/// One accepted push: the parsed message the UI shows beside the raw payload
/// that produced it, so the cap cannot trim them out of step.
class _AcceptedPush {
  const _AcceptedPush(this.message, this.payload);

  final PushMessage message;
  final Map<String, Object?> payload;
}
