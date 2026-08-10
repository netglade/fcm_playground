/// One reason a [NotificationDraft] cannot be sent.
///
/// Carries the field it belongs to so the editor can render it against the
/// right input, and the function can name it in a 400 response.
class DraftProblem {
  const DraftProblem(this.field, this.reason);

  /// Which part of the draft is at fault: `title`, `body` or `data`.
  final String field;

  /// What is wrong with it, phrased for a person to read.
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is DraftProblem && field == other.field && reason == other.reason;

  @override
  int get hashCode => Object.hash(field, reason);

  @override
  String toString() => '$field: $reason';
}
