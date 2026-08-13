import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_app/notifications/notification_presenter.dart';

/// A [NotificationPresenter] that records instead of notifying.
class RecordingNotificationPresenter implements NotificationPresenter {
  /// Every message a banner was requested for, in order.
  final shown = <PushMessage>[];

  final _taps = StreamController<String>.broadcast();

  /// Whether [initialize] ran, so a test can prove the app set the channel up.
  bool initialized = false;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> show(PushMessage message) async => shown.add(message);

  /// Acts as though the user tapped the banner for [id].
  void emitTap(String id) => _taps.add(id);

  @override
  Future<void> dispose() => _taps.close();
}
