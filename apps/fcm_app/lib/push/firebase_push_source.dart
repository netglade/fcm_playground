import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_source.dart';

/// A [PushSource] backed by `firebase_messaging`.
class FirebasePushSource implements PushSource {
  FirebasePushSource(this._messaging);

  final FirebaseMessaging _messaging;
  final _controller = StreamController<Map<String, Object?>>.broadcast();
  StreamSubscription<RemoteMessage>? _subscription;

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  /// Subscribes to foreground messages and replays the message that launched
  /// the app, if there was one.
  Future<void> start() async {
    _subscription = FirebaseMessaging.onMessage.listen(_emit);

    final launchMessage = await _messaging.getInitialMessage();
    if (launchMessage != null) {
      _emit(launchMessage);
    }
  }

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  void _emit(RemoteMessage message) => _controller.add(_toPayload(message));

  /// Flattens a [RemoteMessage] into the flat map `PushMessageParser` expects.
  ///
  /// The notification block supplies defaults; anything in `data` wins, since a
  /// data-only push is the case worth supporting well.
  Map<String, Object?> _toPayload(RemoteMessage message) => {
    'id': message.messageId ?? '',
    'title': message.notification?.title ?? '',
    'body': message.notification?.body ?? '',
    'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
    ...message.data,
  };
}
