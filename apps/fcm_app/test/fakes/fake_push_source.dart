import 'dart:async';

import 'package:fcm_app/domains/push/entities/push_source.dart';
import 'package:fcm_app/domains/push/entities/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

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
  final _taps = StreamController<PushTap>();

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  @override
  Stream<PushTap> get taps => _taps.stream;

  /// Pushes [payload] to listeners as if it had arrived from FCM.
  void emit(Map<String, Object?> payload) => _controller.add(payload);

  /// Acts as though the user tapped the tray notification for [id].
  ///
  /// [from] defaults to `background`, which is what an FCM tray tap ordinarily is, so
  /// the tests that do not care about the state need no change.
  void emitTap(String id, {OpenedFrom from = OpenedFrom.background}) =>
      _taps.add(PushTap(id, from));

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
    // Not awaited: a single-subscription controller's close() future only completes
    // once a listener has taken the done event, and most tests dispose a source
    // nothing subscribed to.
    unawaited(_controller.close());
    unawaited(_taps.close());
  }
}
