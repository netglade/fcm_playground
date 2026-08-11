/// A reason a draft cannot be sent, tied to the field that caused it.
///
/// [field] is what the app renders the message against: `'title'`, `'body'`,
/// `'data'` for the map as a whole, or `'data.<key>'` for one entry.
class DraftProblem {
  const DraftProblem(this.field, this.message);

  /// The offending field's name.
  final String field;

  /// What is wrong with it, phrased to follow the field name in a sentence.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DraftProblem && field == other.field && message == other.message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => '$field $message';
}
