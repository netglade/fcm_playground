import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import '../notifications/notification_presenter.dart';
import '../notifications/silent_notification_presenter.dart';
import '../telemetry/push_telemetry.dart';
import '../telemetry/report_push_event.dart';
import '../telemetry/silent_push_telemetry.dart';
import 'push_payload_store.dart';
import 'push_source.dart';

/// Holds the messages received so far and exposes them to the UI.
///
/// Parsing lives in `core`; this class owns the subscription, the ordering, the
/// de-duplication and the persistence that the widget tree cares about.
class PushInbox extends ChangeNotifier {
  // Initializing formals rather than an initializer list: Dart strips the
  // leading underscore from a private field's initializing-formal parameter
  // name at call sites, so `this._presenter` and `this._setupError` still
  // expose the public `presenter` and `setupError` names the rest of the app
  // and the tests call this constructor with.
  PushInbox(
    this._source, {
    required this._store,
    this._presenter = const SilentNotificationPresenter(),
    this._telemetry = const SilentPushTelemetry(),
    this._setupError,
  });

  /// How many messages are kept, newest first. A bound exists so a long-lived
  /// install cannot grow the stored list without limit; 100 is far more than the
  /// sample needs and still decodes instantly at launch.
  static const maxStoredMessages = 100;

  final PushSource _source;
  final PushPayloadStore _store;
  final NotificationPresenter _presenter;
  final PushTelemetry _telemetry;
  final _parser = const PushMessageParser();
  final _accepted = <_AcceptedPush>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _setupError;
  String? _token;
  String? _pendingOpenId;

  /// A tap whose message the inbox did not hold when it arrived.
  ///
  /// The Android warm-start path: FCM reports the tap as the app resumes, while
  /// the payload is still in the queue the background isolate appended to. The
  /// `opened` event waits here for the payload that carries its trace id, and is
  /// cleared once reported so one press cannot record two opens.
  String? _unreportedOpenId;

  /// Why push is unavailable, or `null` when everything started cleanly.
  ///
  /// Mutable behind a getter because a storage failure discovered during
  /// [restore] belongs in the same banner as a Firebase failure.
  String? get setupError => _setupError;

  /// Received messages, newest first, with repeated ids dropped — FCM does not
  /// guarantee at-most-once delivery.
  List<PushMessage> get messages =>
      List.unmodifiable(_accepted.map((push) => push.message));

  /// Payloads that failed validation, oldest first. Kept so a malformed push is
  /// visible in the UI instead of being silently swallowed.
  List<String> get rejections => List.unmodifiable(_rejections);

  /// The device's registration token once [refreshToken] has resolved.
  String? get token => _token;

  /// Whether a notification tap is waiting to be acted on.
  bool get hasPendingOpen => _pendingOpenId != null;

  /// The message a tap asked to open, or null when there is no tap outstanding
  /// or its message is not held.
  ///
  /// Resolved on every read rather than when the tap arrived: the tap and the
  /// payload come from two different streams, so the message may land after the
  /// request. A `notifyListeners` from either brings the shell back to check.
  PushMessage? get pendingOpen {
    final id = _pendingOpenId;
    if (id == null) {
      return null;
    }

    return _acceptedFor(id)?.message;
  }

  /// Asks the shell to open the message with [id].
  void requestOpen(String id) {
    _pendingOpenId = id;
    // Fire and forget: a tap is handled whether or not it can be reported. The
    // trace id lives on the payload rather than on the message — the parser
    // reserves it — so a tap the inbox cannot resolve has nothing to record
    // against, and the id is held until the payload turns up instead of being
    // recorded against a fabricated trace, which would appear in the matrix as a
    // message nobody sent. It supersedes any earlier unreported tap, because the
    // user has since pressed something else.
    final opened = _acceptedFor(id);
    _unreportedOpenId = opened == null ? id : null;
    if (opened != null) {
      unawaited(
        reportAndFlush(_telemetry, TelemetryEventType.opened, opened.payload),
      );
    }
    notifyListeners();
  }

  /// Called by the shell once it has navigated, so it does not navigate twice.
  void clearPendingOpen() {
    _pendingOpenId = null;
  }

  /// Begins consuming [PushSource.payloads].
  void listen() {
    _subscription = _source.payloads.listen(_onLivePayload);
  }

  /// Loads the kept messages and everything the background isolate left.
  ///
  /// Called once before the first frame. A storage failure surfaces in
  /// [setupError] rather than throwing — persistence failing must not stop the
  /// app from opening, the same principle `main()` already applies to Firebase.
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
      notifyListeners();
    }
  }

  /// Merges anything the background isolate appended since the last drain.
  ///
  /// Called again whenever the UI resumes, because a push arriving while the app
  /// was merely backgrounded would otherwise sit unseen until a restart.
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

  /// Fetches the registration token, ignoring failures — a missing token is
  /// worth showing as absent, not as a crash.
  Future<void> refreshToken() async {
    try {
      _token = await _source.token();
    } catch (error) {
      debugPrint('Could not read FCM token: $error');
      _token = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _onLivePayload(Map<String, Object?> payload) {
    // Reported before parsing, and only for the live stream. A payload the
    // parser rejects still arrived — it is exactly the kind of push the matrix
    // is wanted for — and its trace id is readable whether or not the rest of it
    // is valid. Restored and drained payloads are not arrivals: the background
    // handler recorded those as `received_bg` when they actually landed, and
    // reporting them again on every launch would turn a database read into a
    // delivery.
    unawaited(
      reportAndFlush(_telemetry, TelemetryEventType.receivedFg, payload),
    );
    _ingest(payload, notify: true);
    // Fire and forget: the stream handler is synchronous, and a failed write
    // must not break delivery to the UI.
    unawaited(_save());
  }

  void _ingest(Map<String, Object?> payload, {required bool notify}) {
    try {
      final message = _parser.parse(payload);
      if (_seenIds.add(message.id)) {
        _accepted.insert(0, _AcceptedPush(message, payload));
        if (_accepted.length > maxStoredMessages) {
          // The evicted id stays in _seenIds, so a re-delivery cannot resurrect
          // it mid-session. A restart rebuilds the set from what was kept, which
          // is the only way an evicted message can reappear.
          _accepted.removeLast();
        }
        if (notify) {
          unawaited(_show(message, payload));
        }
        if (message.id == _unreportedOpenId) {
          // Whether or not this arrival notifies: the tap that is waiting came
          // from a message the background isolate stored, so the payload that
          // resolves it arrives through a drain rather than through the stream.
          _unreportedOpenId = null;
          unawaited(
            reportAndFlush(_telemetry, TelemetryEventType.opened, payload),
          );
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    notifyListeners();
  }

  /// Draws the banner for [message], and reports it only once that has worked.
  ///
  /// The order is the whole point: a `displayed` recorded before [show] returned
  /// would claim a notification that a failing presenter never drew, and
  /// "displayed but not seen" is a conclusion someone would then chase on the
  /// device. A failure costs the banner and the event, not the message — which
  /// the inbox is already holding by the time this runs.
  Future<void> _show(PushMessage message, Map<String, Object?> payload) async {
    try {
      await _presenter.show(message);
    } on Object catch (error) {
      debugPrint('No banner for ${message.id}: $error');

      return;
    }

    await reportAndFlush(_telemetry, TelemetryEventType.displayed, payload);
  }

  /// The held push with [id], or null when the inbox does not have it.
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
}

/// One accepted push: the parsed message the UI shows, beside the raw payload
/// that produced it, which is what gets persisted.
///
/// One object rather than two parallel lists, so the message and its payload
/// cannot drift out of step as the cap trims them.
class _AcceptedPush {
  const _AcceptedPush(this.message, this.payload);

  final PushMessage message;
  final Map<String, Object?> payload;
}
