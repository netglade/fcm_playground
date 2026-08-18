import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import '../../../pages/inbox/cubit/inbox_state.dart';
import '../../notifications/data_sources/silent_notification_presenter.dart';
import '../../notifications/entities/notification_presenter.dart';
import '../../telemetry/data_sources/silent_push_telemetry.dart';
import '../../telemetry/entities/push_telemetry.dart';
import '../../telemetry/report_push_event.dart';
import '../entities/push_payload_store.dart';
import '../entities/push_source.dart';

/// Everything about received pushes that outlives a page: the subscription, the
/// ordering, the de-duplication and the persistence.
///
/// App-scoped rather than a cubit, because a push arrives whichever tab is
/// showing and the Sandbox needs the registration token this holds. Only the
/// projection for the screen is a cubit.
class PushRepository {
  PushRepository(
    this._source, {
    required this._store,
    this._presenter = const SilentNotificationPresenter(),
    this._telemetry = const SilentPushTelemetry(),
    this._setupError,
  });

  static const maxStoredMessages = 100;

  final PushSource _source;
  final PushPayloadStore _store;
  final NotificationPresenter _presenter;
  final PushTelemetry _telemetry;
  final _parser = const PushMessageParser();
  final _accepted = <_AcceptedPush>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  // Broadcast because the shell and the inbox page both watch it.
  //
  // `sync: true` is load-bearing: an asynchronous broadcast controller delivers
  // through a microtask scheduled in *the subscriber's* zone, so a watcher
  // subscribed from a widget test's `setUp` — outside the zone `testWidgets`
  // drives the clock of — never hears anything, however long the test pumps.
  final _changes = StreamController<InboxState>.broadcast(sync: true);
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _setupError;
  String? _token;
  String? _pendingOpenId;

  /// A tap whose message the repository did not hold when it arrived — the Android
  /// warm-start path, where FCM reports the tap before the background isolate's payload
  /// has been drained.
  ///
  /// The state travels with the id, because by the time the payload turns up nothing
  /// else remembers which channel the tap came through. Cleared once reported, so one
  /// press cannot record two opens.
  ({String id, OpenedFrom from})? _unreportedOpen;

  Stream<InboxState> get changes => _changes.stream;

  InboxState get state => InboxState(
    messages: messages,
    rejections: rejections,
    token: _token,
    setupError: _setupError,
    pendingOpenId: _pendingOpenId,
  );

  String? get setupError => _setupError;

  List<PushMessage> get messages =>
      List.unmodifiable(_accepted.map((push) => push.message));

  List<String> get rejections => List.unmodifiable(_rejections);

  String? get token => _token;

  bool get hasPendingOpen => _pendingOpenId != null;

  /// The message a tap asked to open, or null when there is no tap outstanding
  /// or its message is not held.
  ///
  /// Resolved on every read rather than when the tap arrived: the tap and the
  /// payload come from two different streams, so the message may land after the
  /// request.
  PushMessage? get pendingOpen => state.pendingOpen;

  void requestOpen(String id, OpenedFrom from) {
    _pendingOpenId = id;
    // A tap is handled whether or not it can be reported. The trace id lives on the
    // payload, so an unresolvable tap is held until the payload turns up rather than
    // recorded against a fabricated trace.
    final opened = _acceptedFor(id);
    _unreportedOpen = opened == null ? (id: id, from: from) : null;
    if (opened != null) {
      unawaited(
        reportAndFlush(
          _telemetry,
          TelemetryEventType.opened,
          opened.payload,
          detail: from.wireName,
        ),
      );
    }
    _publish();
  }

  /// Called by the shell once it has navigated, so it does not navigate twice.
  ///
  /// Published like every other change: the tap is a field of the snapshot on
  /// [changes], so a silent clear would leave watchers holding a state that
  /// still claims a tap is outstanding. Clearing *before* navigating means the
  /// extra event carries no pending open, so the shell's guard does nothing.
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
  /// persistence failing must not stop the app from opening.
  Future<void> restore() async {
    try {
      final stored = await _store.loadInbox();
      final pending = await _store.takePending();
      // Stored payloads are newest first and each ingest inserts at the front,
      // so they go in reversed. Pending payloads were appended oldest first.
      for (final payload in stored.reversed) {
        _ingest(payload, notify: false);
      }
      for (final payload in pending) {
        _ingest(payload, notify: false);
      }
      await _save();
    } catch (error) {
      _setupError ??= 'Stored pushes could not be read: $error';
      _publish();
    }
  }

  /// Merges anything the background isolate appended since the last drain.
  Future<void> drainPending() async {
    final pending = await _store.takePending();
    if (pending.isEmpty) {
      return;
    }

    for (final payload in pending) {
      _ingest(payload, notify: false);
    }
    await _save();
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
  /// Both closes are unawaited deliberately: a controller's `close()` future
  /// only completes once a listener has taken the done event, so awaiting one
  /// that was never listened to — the ordinary case in a test — never returns.
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_changes.close());
  }

  void _onLivePayload(Map<String, Object?> payload) {
    // Reported before parsing, and only for the live stream. A rejected payload
    // still arrived, and its trace id is readable either way. Restored and
    // drained payloads were already recorded as `received_bg` when they landed.
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
          // The evicted id stays in _seenIds, so a re-delivery cannot resurrect
          // it mid-session. A restart rebuilds the set from what was kept.
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
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    _publish();
  }

  /// Draws the banner for [message], and reports it only once that has worked.
  ///
  /// The order matters: a `displayed` recorded before [show] returned would
  /// claim a notification a failing presenter never drew.
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

  void _publish() {
    _changes.add(state);
  }
}

/// One accepted push: the parsed message the UI shows, beside the raw payload
/// that produced it, so the two cannot drift out of step as the cap trims them.
class _AcceptedPush {
  const _AcceptedPush(this.message, this.payload);

  final PushMessage message;
  final Map<String, Object?> payload;
}
