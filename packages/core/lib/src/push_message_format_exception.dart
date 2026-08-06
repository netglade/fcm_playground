/// Thrown when a raw push payload cannot be turned into a `PushMessage`.
///
/// Carries the offending field so the caller can log something more useful
/// than "malformed message".
class PushMessageFormatException implements Exception {
  const PushMessageFormatException(this.field, this.reason);

  /// Payload key that failed validation.
  final String field;

  /// Why it failed, in a form safe to show in a log.
  final String reason;

  @override
  String toString() => 'PushMessageFormatException($field): $reason';
}
