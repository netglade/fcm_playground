/// Thrown when a raw push payload cannot be turned into a `PushMessage`, carrying
/// the offending field so a log can say more than "malformed message".
class PushMessageFormatException implements Exception {
  const PushMessageFormatException(this.field, this.reason);

  final String field;

  final String reason;

  @override
  String toString() => 'PushMessageFormatException($field): $reason';
}
