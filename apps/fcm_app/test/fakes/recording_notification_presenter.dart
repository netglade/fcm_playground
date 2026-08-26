import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_app/domains/notifications/notification_presenter.dart';
import 'package:fcm_app/domains/push/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationPresenter] that records instead of notifying.
class RecordingNotificationPresenter implements NotificationPresenter {
  /// A presenter whose [show] fails when [failing], and which does not return until
  /// [gate] completes.
  ///
  /// Both exist for the `displayed` hook, which must fire after a banner was drawn
  /// and not merely after one was asked for.
  // `this._gate` rather than an initializer list: Dart strips the leading underscore
  // from a private field's initializing-formal parameter name, so callers still pass
  // the public `gate:`.
  RecordingNotificationPresenter({this.failing = false, this._gate});

  /// Whether [show] throws, as a plugin without a channel does.
  final bool failing;

  final Future<void>? _gate;

  /// Every message a banner was requested for, in order.
  final shown = <PushMessage>[];

  final _taps = StreamController<PushTap>.broadcast();
  final _dismissals = StreamController<String>.broadcast();

  /// Whether [initialize] ran, so a test can prove the app set the channel up.
  bool initialized = false;

  /// How many times [clearAll] ran, so a widget test can prove a button reached
  /// this presenter.
  var cleared = 0;

  @override
  Stream<PushTap> get taps => _taps.stream;

  @override
  Stream<String> get dismissals => _dismissals.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> show(PushMessage message) async {
    // Recorded before the gate and before the failure, so `shown` means "a banner
    // was attempted".
    shown.add(message);
    await _gate;
    if (failing) {
      throw StateError('the notification channel is unavailable');
    }
  }

  /// Acts as though the user tapped the banner for [id]. Always foreground, because
  /// that is the only kind of banner this presenter stands in for.
  void emitTap(String id) => _taps.add(PushTap(id, OpenedFrom.foreground));

  @override
  Future<void> clearAll() async {
    cleared++;
  }

  @override
  Future<void> dispose() async {
    await _taps.close();
    await _dismissals.close();
  }
}
