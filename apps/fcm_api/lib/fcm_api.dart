/// A local HTTP server with one endpoint that sends a push through FCM.
///
/// The interesting logic is in `sendMessage`, which is pure — no socket, no
/// credential — so the payload and the status codes are unit-testable
/// directly.
library;

export 'src/api_router.dart';
export 'src/events_handler.dart';
export 'src/fcm_send_exception.dart';
export 'src/fcm_sender.dart';
export 'src/http_v1_fcm_sender.dart';
export 'src/in_memory_run_store.dart';
export 'src/in_memory_telemetry_store.dart';
export 'src/new_trace_id.dart';
export 'src/run_store.dart';
export 'src/send_message.dart';
export 'src/send_outcome.dart';
export 'src/send_scheduler.dart';
export 'src/server_config.dart';
export 'src/sqlite_run_store.dart';
export 'src/sqlite_telemetry_store.dart';
export 'src/telemetry_store.dart';
