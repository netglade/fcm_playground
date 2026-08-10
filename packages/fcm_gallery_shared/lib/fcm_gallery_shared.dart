/// The contract shared by `fcm_app` and `fcm_functions`.
///
/// Pure Dart on purpose: the app, the functions and their tests all import this
/// library, so it must not drag in Flutter or the Firebase SDKs.
library;

export 'src/notification_delivery.dart';
export 'src/notification_draft.dart';
export 'src/notification_event.dart';
export 'src/notification_priority.dart';
export 'src/wire_named.dart';
