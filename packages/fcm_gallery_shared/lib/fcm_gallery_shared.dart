/// The contract shared by `fcm_app` and `fcm_functions`.
///
/// Pure Dart on purpose: the app, the functions and their tests all import this
/// library, so it must not drag in Flutter or the Firebase SDKs.
library;

export 'src/draft_problem.dart';
export 'src/notification_delivery.dart';
export 'src/notification_draft.dart';
export 'src/notification_draft_validator.dart';
export 'src/notification_event.dart';
export 'src/notification_priority.dart';
export 'src/notification_scenario.dart';
export 'src/send_notification_endpoint.dart';
export 'src/send_notification_request.dart';
export 'src/send_notification_response.dart';
export 'src/wire_named.dart';
