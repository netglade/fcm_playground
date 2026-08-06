import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import 'push_source.dart';

/// Holds the messages received so far and exposes them to the UI.
///
/// Parsing lives in `core`; this class only owns the subscription, ordering and
/// de-duplication that the widget tree cares about.
class PushInbox extends ChangeNotifier {
  PushInbox(this._source, {this.setupError});

  /// Why push is unavailable, or `null` when everything started cleanly.
  final String? setupError;

  final PushSource _source;
  final _parser = const PushMessageParser();
  final _messages = <PushMessage>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _token;

  /// Received messages, newest first, with repeated ids dropped — FCM does not
  /// guarantee at-most-once delivery.
  List<PushMessage> get messages => List.unmodifiable(_messages);

  /// Payloads that failed validation, oldest first. Kept so a malformed push is
  /// visible in the UI instead of being silently swallowed.
  List<String> get rejections => List.unmodifiable(_rejections);

  /// The device's registration token once [refreshToken] has resolved.
  String? get token => _token;

  /// Begins consuming [PushSource.payloads].
  void listen() {
    _subscription = _source.payloads.listen(_onPayload);
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

  void _onPayload(Map<String, Object?> payload) {
    try {
      final message = _parser.parse(payload);
      if (_seenIds.add(message.id)) {
        _messages.insert(0, message);
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    notifyListeners();
  }
}
