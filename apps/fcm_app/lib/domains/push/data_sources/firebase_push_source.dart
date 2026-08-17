import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../entities/push_source.dart';
import '../entities/remote_message_payload.dart';

/// A [PushSource] backed by `firebase_messaging`.
class FirebasePushSource implements PushSource {
  FirebasePushSource(this._messaging);

  final FirebaseMessaging _messaging;

  // Single-subscription, not broadcast: start() emits the launch message before
  // PushRepository subscribes, and a broadcast controller discards events added
  // while nothing is listening. PushRepository is the only subscriber either way.
  final _controller = StreamController<Map<String, Object?>>();
  final _taps = StreamController<String>();
  StreamSubscription<RemoteMessage>? _subscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  @override
  Stream<String> get taps => _taps.stream;

  Future<void> start() async {
    _subscription = FirebaseMessaging.onMessage.listen(_emit);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onOpened,
    );

    // iOS suppresses the foreground banner unless asked. Android shows nothing
    // either way, which is what LocalNotificationPresenter is for.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final launchMessage = await _messaging.getInitialMessage();
    if (launchMessage != null) {
      // Payload first, so the inbox holds the message before the tap asks to
      // open it. Both controllers deliver in the order added.
      _emit(launchMessage);
      _onOpened(launchMessage);
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
    await _openedSubscription?.cancel();

    // Not awaited: a single-subscription controller's close() future only
    // completes once a listener has received the done event, and dispose can run
    // before anything ever subscribes. Closing still stops further adds.
    unawaited(_controller.close());
    unawaited(_taps.close());
  }

  void _emit(RemoteMessage message) =>
      _controller.add(remoteMessageToPayload(message));

  void _onOpened(RemoteMessage message) {
    final id = remoteMessageToPayload(message)['id'];
    if (id is String && id.isNotEmpty) {
      _taps.add(id);
    }
  }
}
