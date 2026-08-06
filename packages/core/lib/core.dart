/// Platform-independent domain logic shared across the FCM sample app.
///
/// This library deliberately depends on nothing but `dart:core`, so everything
/// in it can be exercised with `dart test` — no device, no Flutter binding and
/// no Firebase project required.
library;

export 'src/push_message.dart';
export 'src/push_message_format_exception.dart';
export 'src/push_message_parser.dart';
