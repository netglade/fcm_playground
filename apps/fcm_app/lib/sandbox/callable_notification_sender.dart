import 'package:cloud_functions/cloud_functions.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_sender.dart';

/// The production [NotificationSender], calling the `sendNotification`
/// callable in `apps/fcm_functions`.
class CallableNotificationSender implements NotificationSender {
  const CallableNotificationSender(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    final callable = _functions.httpsCallable(
      SendNotificationEndpoint.deployedId,
    );
    final result = await callable.call<Object?>(request.toJson());
    final data = result.data;
    // The plugin hands back Map<Object?, Object?> on Android, so the map is
    // rebuilt with String keys rather than cast.
    if (data is! Map) {
      throw StateError(
        '${SendNotificationEndpoint.deployedId} returned '
        '${data.runtimeType}, expected a JSON object',
      );
    }

    return SendNotificationResponse.fromJson(
      data.map((key, value) => MapEntry('$key', value)),
    );
  }
}
