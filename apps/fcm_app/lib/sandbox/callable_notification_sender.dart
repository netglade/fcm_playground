import 'package:cloud_functions/cloud_functions.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_sender.dart';

/// The production [NotificationSender], calling the `sendNotification`
/// callable in `apps/fcm_functions`.
class CallableNotificationSender implements NotificationSender {
  const CallableNotificationSender(this._functions);

  /// The deployed function's id, which is **not** the string passed to
  /// `onCallWithData`.
  ///
  /// `firebase_functions` runs every registered name through its
  /// `toCloudRunId` sanitiser, so `sendNotification` in
  /// `register_functions.dart` becomes `send-notification` in the generated
  /// `functions.yaml`, in the deployed Cloud Run service, and in the path the
  /// container routes on. Calling `sendNotification` here would target a
  /// function that does not exist.
  ///
  /// Changing either side without the other breaks the call at runtime, not at
  /// compile time. Task 13's end-to-end step is what catches that.
  static const functionName = 'send-notification';

  final FirebaseFunctions _functions;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    final callable = _functions.httpsCallable(functionName);
    final result = await callable.call<Object?>(request.toJson());
    final data = result.data;
    // The plugin hands back Map<Object?, Object?> on Android, so the map is
    // rebuilt with String keys rather than cast.
    if (data is! Map) {
      throw StateError(
        '$functionName returned ${data.runtimeType}, expected a JSON object',
      );
    }

    return SendNotificationResponse.fromJson(
      data.map((key, value) => MapEntry('$key', value)),
    );
  }
}
