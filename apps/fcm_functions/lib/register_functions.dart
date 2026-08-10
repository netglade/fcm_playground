import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_functions/firebase_functions.dart';

import 'admin_fcm_message_sender.dart';
import 'send_notification_handler.dart';

/// Registers every function this codebase deploys.
///
/// Lives in `lib/` rather than in `bin/server.dart` because the
/// `firebase_functions` builder resolves declarations across every Dart file in
/// the package, so the entry point can stay a single line.
///
/// The callable is unauthenticated: the app has no Firebase Auth, and it can
/// only ask for a push to the token it supplies itself. `maxInstances` and
/// `timeoutSeconds` cap what abuse can cost. App Check is the production
/// answer and is deliberately out of scope — see the design document.
///
/// Uses `onCall` rather than `onCallWithData` so the request body reaches
/// `handleSendNotification` unparsed. `onCallWithData`'s `fromJson` runs
/// eagerly, inside the same try/catch that turns an uncaught exception into an
/// opaque `internal` error — parsing there would defeat the point of parsing
/// inside the handler at all. Both methods produce an identical manifest entry
/// (verified by regenerating `functions.yaml`), so this changes nothing
/// observable about the deployed endpoint.
void registerFunctions(Firebase firebase) {
  firebase.https.onCall(
    name: SendNotificationEndpoint.registeredName,
    options: const CallableOptions(
      maxInstances: Instances(3),
      timeoutSeconds: TimeoutSeconds(30),
    ),
    (request, _) async {
      final data = request.data;
      final response = await handleSendNotification(
        data is Map<String, dynamic> ? data : const {},
        sender: AdminFcmMessageSender(firebase.adminApp.messaging()),
      );

      return CallableResult(response);
    },
  );
}
