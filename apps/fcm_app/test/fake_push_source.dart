import 'dart:async';

import 'package:fcm_app/push/push_source.dart';

/// A [PushSource] driven by the test rather than by Firebase.
class FakePushSource implements PushSource {
  FakePushSource({this.tokenValue = 'fake-token', this.tokenThrows = false});

  /// Token handed back by [token] when [tokenThrows] is false.
  final String? tokenValue;

  /// When true, [token] fails — used to check the inbox degrades gracefully.
  final bool tokenThrows;

  // Single-subscription, mirroring FirebasePushSource: a payload emitted before
  // anything listens must still be delivered.
  final _controller = StreamController<Map<String, Object?>>();
  final _taps = StreamController<String>();

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  @override
  Stream<String> get taps => _taps.stream;

  /// Pushes [payload] to listeners as if it had arrived from FCM.
  void emit(Map<String, Object?> payload) => _controller.add(payload);

  /// Acts as though the user tapped the tray notification for [id].
  void emitTap(String id) => _taps.add(id);

  @override
  Future<String?> token() {
    if (tokenThrows) {
      return Future<String?>.error(StateError('no token'));
    }

    return Future<String?>.value(tokenValue);
  }

  @override
  Future<bool> requestPermission() => Future<bool>.value(true);

  @override
  Future<void> dispose() async {
    // Not awaited: a single-subscription controller's close() future only
    // completes once a listener has received the done event, and most tests
    // dispose a source that nothing ever subscribed to (taps, in particular).
    // Closing still stops further adds either way.
    unawaited(_controller.close());
    unawaited(_taps.close());
  }
}
