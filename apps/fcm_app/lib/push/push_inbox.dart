import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../notifications/notification_presenter.dart';
import '../notifications/silent_notification_presenter.dart';
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
    this._setupError,
  });

  /// How many messages are kept, newest first. A bound exists so a long-lived
  /// install cannot grow the stored list without limit; 100 is far more than the
  /// sample needs and still decodes instantly at launch.
  static const maxStoredMessages = 100;

  final PushSource _source;
  final PushPayloadStore _store;
  final NotificationPresenter _presenter;
  final _parser = const PushMessageParser();
  final _accepted = <_AcceptedPush>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _setupError;
  String? _token;

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
          unawaited(_presenter.show(message));
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    notifyListeners();
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
