import 'dart:async';

import 'package:fcm_app/push/push_source.dart';

/// A [PushSource] driven by the test rather than by Firebase.
class FakePushSource implements PushSource {
  FakePushSource({this.tokenValue = 'fake-token', this.tokenThrows = false});

  /// Token handed back by [token] when [tokenThrows] is false.
  final String? tokenValue;

  /// When true, [token] fails — used to check the inbox degrades gracefully.
  final bool tokenThrows;

  final _controller = StreamController<Map<String, Object?>>.broadcast();

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  /// Pushes [payload] to listeners as if it had arrived from FCM.
  void emit(Map<String, Object?> payload) => _controller.add(payload);

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
  Future<void> dispose() => _controller.close();
}
