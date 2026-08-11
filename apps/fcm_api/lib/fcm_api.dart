/// A local HTTP server with one endpoint that sends a push through FCM.
///
/// The interesting logic is in [NotificationMessage] and `sendNotification`,
/// both of which are pure — no socket, no credential — so the payload and the
/// status codes are unit-testable directly.
library;

export 'src/api_router.dart';
export 'src/fcm_send_exception.dart';
export 'src/fcm_sender.dart';
export 'src/http_v1_fcm_sender.dart';
export 'src/notification_message.dart';
export 'src/send_notification.dart';
export 'src/send_outcome.dart';
