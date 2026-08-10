import 'package:cloud_functions/cloud_functions.dart';

import 'callable_notification_sender.dart';
import 'notification_sender.dart';
import 'unavailable_notification_sender.dart';

/// Host running the Functions emulator, supplied at build time.
///
/// Empty means "use the deployed function". Pass a value with
/// `--dart-define=FUNCTIONS_EMULATOR_HOST=…`: `10.0.2.2` from the Android
/// emulator, or the machine's LAN address from a physical device. It cannot be
/// hard-coded because it differs per developer and per device.
const functionsEmulatorHost = String.fromEnvironment('FUNCTIONS_EMULATOR_HOST');

/// Port from the `emulators` block in the root `firebase.json`.
const functionsEmulatorPort = 5001;

/// The sender the sandbox should use.
///
/// Returns [UnavailableNotificationSender] when Firebase never started, so the
/// sandbox still renders and reports the same reason the inbox banner does,
/// rather than crashing on first use.
NotificationSender buildNotificationSender({
  required bool firebaseStarted,
  required String? setupError,
}) {
  if (!firebaseStarted) {
    return UnavailableNotificationSender(
      setupError ?? 'Firebase is not configured, so nothing can be sent.',
    );
  }

  final functions = FirebaseFunctions.instance;
  if (functionsEmulatorHost.isNotEmpty) {
    functions.useFunctionsEmulator(
      functionsEmulatorHost,
      functionsEmulatorPort,
    );
  }

  return CallableNotificationSender(functions);
}
