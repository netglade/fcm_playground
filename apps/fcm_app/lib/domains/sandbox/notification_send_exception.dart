import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A send that did not happen, with a message written for the person holding the
/// phone rather than for a log.
class NotificationSendException implements Exception {
  const NotificationSendException(this.message, {this.field});

  /// Rewraps the server's own error, so a 400 keeps the field it blamed.
  factory NotificationSendException.fromApiError(ApiError error) =>
      NotificationSendException(error.message, field: error.field);

  /// Shown in the UI as-is.
  final String message;

  /// The draft field at fault, when the server named one.
  final String? field;

  @override
  String toString() => message;
}
