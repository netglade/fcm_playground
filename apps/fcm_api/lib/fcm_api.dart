/// A local HTTP server with one endpoint that sends a push through FCM.
///
/// The interesting logic is in `sendMessage`, which is pure — no socket, no
/// credential — so the payload and the status codes are unit-testable
/// directly.
library;

export 'src/src.dart';
