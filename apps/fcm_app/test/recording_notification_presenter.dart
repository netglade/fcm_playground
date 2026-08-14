import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_app/notifications/notification_presenter.dart';

/// A [NotificationPresenter] that records instead of notifying.
class RecordingNotificationPresenter implements NotificationPresenter {
  /// A presenter whose [show] fails when [failing], and which does not return
  /// until [gate] completes.
  ///
  /// Both exist for the `displayed` hook, which must fire after a banner was
  /// drawn and not merely after one was asked for: [gate] holds `show` open so a
  /// test can look at the moment in between, and [failing] is the case where
  /// that moment never ends well. Reporting a notification that was never drawn
  /// would make "displayed but not seen" a conclusion someone chases on the
  /// device.
  // `this._gate` rather than an initializer list: Dart strips the leading
  // underscore from a private field's initializing-formal parameter name, so
  // callers still pass the public `gate:`.
  RecordingNotificationPresenter({this.failing = false, this._gate});

  /// Whether [show] throws, as a plugin without a channel does.
  final bool failing;

  final Future<void>? _gate;

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
  Future<void> show(PushMessage message) async {
    // Recorded before the gate and before the failure, so `shown` means "a
    // banner was attempted": a test asserting that nothing was reported needs
    // to show the attempt happened at all.
    shown.add(message);
    await _gate;
    if (failing) {
      throw StateError('the notification channel is unavailable');
    }
  }

  /// Acts as though the user tapped the banner for [id].
  void emitTap(String id) => _taps.add(id);

  @override
  Future<void> dispose() => _taps.close();
}
