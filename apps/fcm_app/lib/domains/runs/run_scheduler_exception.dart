import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A run that was not scheduled, read or cancelled, with a message written for the
/// person holding the phone.
///
/// Its own type rather than `NotificationSendException`: this is a different domain,
/// and having `domains/runs` reach into `domains/sandbox` for an exception would
/// couple them for the sake of twelve lines.
class RunSchedulerException implements Exception {
  const RunSchedulerException(this.message);

  factory RunSchedulerException.fromApiError(ApiError error) =>
      RunSchedulerException(error.message);

  /// Shown in the UI as-is.
  final String message;

  @override
  String toString() => message;
}
