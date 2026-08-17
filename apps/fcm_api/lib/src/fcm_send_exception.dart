/// A send FCM refused.
///
/// [status] is FCM's own error code — `UNREGISTERED`, `INVALID_ARGUMENT`,
/// `QUOTA_EXCEEDED` and so on — kept verbatim so the handler can decide the HTTP
/// status without re-parsing prose.
class FcmSendException implements Exception {
  const FcmSendException({required this.status, required this.message});

  final String status;

  final String message;

  @override
  String toString() => 'FcmSendException($status): $message';
}
