/// The notification contract shared by the Sandbox page and the send API.
///
/// Pure Dart, so both a Flutter app and a server process can depend on it, and
/// every rule in it is exercised by plain `dart test`.
library;

export 'src/api_error.dart';
export 'src/draft_problem.dart';
export 'src/message/android_message_priority.dart';
export 'src/message/android_notification_priority.dart';
export 'src/message/json_object_reader.dart';
export 'src/message/notification_proxy.dart';
export 'src/message/notification_visibility.dart';
export 'src/notification_draft.dart';
export 'src/notification_draft_validator.dart';
export 'src/notification_scenario.dart';
export 'src/send_notification_request.dart';
export 'src/send_notification_response.dart';
